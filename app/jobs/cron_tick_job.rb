# app/jobs/cron_tick_job.rb
class CronTickJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by(id: campaign_id)
    return unless campaign && campaign.status == "queued"

    # Respect environment rules (domain gating for staging, etc.)
    # Do your Mandrill sending here (you said you’ll wire that next).

    # Example skeleton:
    begin
      # Dispatch emails for this campaign…
      # If everything sent:
      campaign.update!(status: "sent")
    rescue => e
      campaign.update!(status: "failed", failure_reason: e.message)
      raise
    end
  end
end