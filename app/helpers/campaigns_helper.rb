module CampaignsHelper
  # Heuristic: if scheduled_at exists and is ~ the created time, we treat it as "Send now"
  def delivery_badge(campaign)
    label =
      if campaign.scheduled_at.present? && (campaign.scheduled_at - campaign.created_at).abs <= 5.minutes
        "Send now"
      else
        "Scheduled"
      end

    content_tag(:span, label, class: "px-2 py-0.5 rounded bg-white/10")
  end

  # Show scheduler user if present
  def campaign_scheduler(campaign)
    if campaign.respond_to?(:user) && campaign.user.present?
      "#{campaign.user.first_name} #{campaign.user.last_name}".strip.presence || campaign.user.email
    else
      "—"
    end
  end
end