# app/jobs/campaign_trigger_job.rb
class CampaignTriggerJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)

    # Respect global safety flags
    s = AppSetting.instance
    if s.scheduling_on_hold || !s.cron_enabled
      Rails.logger.info "[campaign_job] skipped (hold=#{s.scheduling_on_hold}, cron=#{s.cron_enabled})"
      return
    end

    # Guard: only proceed from SCHEDULED
    updated = Campaign.where(id: campaign.id, status: "SCHEDULED")
                      .update_all(status: "SENT", failure_reason: "processing")
    return if updated.zero? # already processed elsewhere

    begin
      sent = MandrillSender.new.send_campaign!(campaign)
      # optional: if some failed, you can mark PARTIAL
      failed = campaign.emails.where(status: "FAILED").count
      if sent.positive? && failed.positive?
        campaign.update_columns(status: "PARTIAL", failure_reason: nil)
      else
        campaign.update_columns(status: "SENT", failure_reason: nil)
      end
    rescue => e
      campaign.update_columns(status: "FAILED", failure_reason: e.message)
      raise
    end
  end
end