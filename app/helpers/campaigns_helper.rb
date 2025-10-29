module CampaignsHelper
  def immediate_send?(c)
    return true if c.scheduled_at.blank?
    return false if c.status == "SCHEDULED"
    # heuristic: scheduled_at ~= created_at means it was an immediate fire
    (c.scheduled_at - c.created_at).abs <= 2.minutes
  end

  def delivery_badge(c)
    now = Time.current

    if immediate_send?(c)
      return content_tag(:span, "Send now", class: "px-2 py-0.5 rounded bg-emerald-600/20 text-emerald-200")
    end

    # scheduled_at present and not immediate
    if c.scheduled_at > now
      content_tag(:span, "Scheduled", class: "px-2 py-0.5 rounded bg-blue-600/20 text-blue-200")
    else
      if c.status == "SCHEDULED"
        content_tag(:span, "Due", class: "px-2 py-0.5 rounded bg-amber-600/20 text-amber-200")
      else
        # processed scheduled run
        content_tag(:span, "Scheduled", class: "px-2 py-0.5 rounded bg-blue-600/20 text-blue-200")
      end
    end
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