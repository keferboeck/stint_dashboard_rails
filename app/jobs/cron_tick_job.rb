# app/jobs/cron_tick_job.rb
require "net/http"
require "json"

class CronTickJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by(id: campaign_id)
    unless campaign
      Rails.logger.warn("[CronTickJob] campaign #{campaign_id} not found")
      return
    end

    unless campaign.status == "SCHEDULED"
      Rails.logger.info("[CronTickJob] skip campaign=#{campaign.id} status=#{campaign.status}")
      return
    end

    settings = AppSetting.instance
    if settings.scheduling_on_hold
      Rails.logger.info("[CronTickJob] HOLD active, skip #{campaign.id}")
      return
    end
    unless settings.cron_enabled
      Rails.logger.info("[CronTickJob] cron disabled, skip #{campaign.id}")
      return
    end

    pending = campaign.emails.where(status: "PENDING")
    if pending.none?
      Rails.logger.info("[CronTickJob] no pending emails for #{campaign.id}, marking SENT")
      campaign.update!(status: "SENT")
      return
    end

    sent_count = 0
    failed_count = 0

    pending.find_each do |email|
      gate_result = gate_sending?(email.address)
      case gate_result
      when :block_dev
        email.update!(status: "FAILED", error_message: "Blocked in development environment")
        failed_count += 1
        next
      when :block_staging
        email.update!(status: "FAILED", error_message: "Blocked in staging: non-whitelisted domain")
        failed_count += 1
        next
      end

      begin
        resp = mandrill_send_template!(
          to:          email.address,
          template:    campaign.template_name,
          subject:     campaign.subject,
          preview:     campaign.preview_text,
          vars:        email.custom_fields || {},
          from_email:  ENV.fetch("OUTBOUND_FROM_EMAIL", "no-reply@stint.co"),
          from_name:   ENV.fetch("OUTBOUND_FROM_NAME", "Stint")
        )

        # Mandrill returns an array per recipient
        result = Array(resp).first || {}
        status = result["status"] # "sent", "queued", "scheduled", "rejected", "invalid"
        reject_reason = result["reject_reason"]

        if %w[sent queued scheduled].include?(status)
          email.update!(status: "SENT", sent_at: Time.current)
          sent_count += 1
        else
          email.update!(status: "FAILED", error_message: (reject_reason || status || "mandrill_error"))
          failed_count += 1
        end
      rescue => e
        email.update!(status: "FAILED", error_message: e.message)
        failed_count += 1
        Rails.logger.error("[CronTickJob] Mandrill error for email #{email.id} #{email.address}: #{e.class}: #{e.message}")
      end
    end

    new_status = failed_count.positive? ? "FAILED" : "SENT"
    campaign.update!(status: new_status)
    Rails.logger.info("[CronTickJob] campaign #{campaign.id} done sent=#{sent_count} failed=#{failed_count} status=#{new_status}")
  end

  private

  # Returns:
  #   :ok            -> allow send
  #   :block_dev     -> block in development (non keferboeck.com)
  #   :block_staging -> block in staging (non stint/keferboeck)
  def gate_sending?(address)
    domain = address.to_s.split("@").last.to_s.downcase

    if Rails.env.development?
      # dev must still go through Mandrill, but only for keferboeck.com
      allowed = %w[keferboeck.com]
      return allowed.include?(domain) ? :ok : :block_dev
    elsif Rails.env.staging?
      allowed = %w[stint.co keferboeck.com]
      return allowed.include?(domain) ? :ok : :block_staging
    else
      :ok # production allows all
    end
  end

  # Minimal Mandrill call without extra gems.
  # Endpoint: /messages/send-template.json
  def mandrill_send_template!(to:, template:, subject:, vars:, from_email:, from_name:, preview: nil)
    api_key = ENV["MANDRILL_API_KEY"]
    raise "MANDRILL_API_KEY missing" if api_key.blank?

    uri = URI("https://mandrillapp.com/api/1.0/messages/send-template.json")
    template_content = [] # we use merge vars instead of editing template blocks

    message = {
      subject:     subject,
      from_email:  from_email,
      from_name:   from_name,
      to:          [{ email: to, type: "to" }],
      merge_language: "handlebars",
      merge: true,
      global_merge_vars: [],
      merge_vars: [
        {
          rcpt: to,
          vars: (vars || {}).map { |k, v| { name: k.to_s, content: v.to_s } }
        }
      ],
      tags: ["stint-dashboard"],
      headers: (preview.present? ? { "X-Preview-Text" => preview.to_s } : {})
    }

    req_body = {
      key: api_key,
      template_name: template,
      template_content: template_content,
      message: message,
      async: true
    }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
    req.body = req_body

    res = http.request(req)
    raise "Mandrill HTTP #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end
end