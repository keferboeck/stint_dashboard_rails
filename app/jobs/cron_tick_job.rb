# app/jobs/cron_tick_job.rb
class CronTickJob < ApplicationJob
  queue_as :default

  # Performs a one-off send attempt for a single campaign.
  # Enqueue with: CronTickJob.perform_later(campaign.id)
  def perform(campaign_id)
    settings = AppSetting.instance

    # Safety switches
    return unless settings.cron_enabled
    return if settings.scheduling_on_hold

    campaign = Campaign.find_by(id: campaign_id)
    return unless campaign

    # Only send when truly due
    return unless campaign.status == "SCHEDULED"
    return unless campaign.scheduled_at.present? && campaign.scheduled_at <= Time.current

    # Domain gate for non-prod
    allowed_domains =
      if Rails.env.development?
        %w[keferboeck.com]
      elsif Rails.env.staging?
        %w[stint.co keferboeck.com]
      else
        nil # prod = everything allowed
      end

    pending = campaign.emails.where(status: "PENDING")
    if pending.none?
      campaign.update!(status: "SENT")
      Rails.logger.info("[CronTickJob] Campaign ##{campaign.id}: no pending emails; marked SENT")
      return
    end

    total    = pending.count
    sent_ok  = 0
    errors   = []

    pending.find_each do |email|
      begin
        # Skip disallowed addresses in gated envs
        if allowed_domains
          domain = email.address.to_s.split("@").last.to_s.downcase
          unless allowed_domains.include?(domain)
            email.update!(status: "FAILED", error_message: "Blocked by env domain gate")
            next
          end
        end

        # === Mandrill send goes here ===
        # Example (adjust to your MandrillClient API):
        # MandrillClient.new.send_template(
        #   template:     campaign.template_name,
        #   subject:      campaign.subject,
        #   to:           email.address,
        #   preview_text: campaign.preview_text,
        #   merge_vars:   email.custom_fields || {}
        # )

        # If it sent without raising:
        email.update!(status: "SENT", sent_at: Time.current)
        sent_ok += 1

      rescue => e
        email.update!(status: "FAILED", error_message: e.message)
        errors << "#{email.address}: #{e.class} #{e.message}"
        Rails.logger.warn("[CronTickJob] Email failed (campaign ##{campaign.id}): #{email.address} -> #{e.class}: #{e.message}")
      end
    end

    if errors.empty?
      campaign.update!(status: "SENT")
      Rails.logger.info("[CronTickJob] Campaign ##{campaign.id}: all #{total} emails SENT")
    else
      campaign.update!(status: "FAILED", failure_reason: errors.first&.to_s&.truncate(500))
      Rails.logger.warn("[CronTickJob] Campaign ##{campaign.id}: partial/total failure; first error: #{errors.first}")
    end
  end
end