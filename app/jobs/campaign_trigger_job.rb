class CampaignTriggerJob < ApplicationJob
  queue_as :default

  # Claim campaign up front so it cannot run twice.
  def perform(campaign_id)
    c = Campaign.find(campaign_id)
    return unless c.status == 'SCHEDULED'

    claimed = Campaign.where(id: c.id, status: 'SCHEDULED')
                      .update_all(status: 'SENT', failure_reason: 'processing')
    return if claimed.zero?

    sender = MandrillSender.new
    sent = 0
    failed = 0

    Email.where(campaign_id: c.id, status: 'PENDING').find_each do |e|
      begin
        sender.send_template(
          template_name: c.template_name,
          subject: c.subject,
          preview_text: c.preview_text,
          to_address: e.address,
          merge_vars: (e.custom_fields || {})
        )
        e.update!(status: 'SENT', sent_at: Time.current)
        sent += 1
      rescue => ex
        e.update!(status: 'FAILED', error_message: ex.message)
        failed += 1
      end
    end

    if failed > 0
      c.update!(status: 'FAILED', failure_reason: "sent=#{sent} failed=#{failed}")
    else
      c.update!(status: 'SENT', failure_reason: nil)
    end
  end
end