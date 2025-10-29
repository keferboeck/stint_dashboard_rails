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

  def campaign_sent_counts(campaign)
    counts  = campaign.emails.group(:status).count
    sent    = counts["SENT"].to_i
    failed  = counts["FAILED"].to_i
    pending = counts["PENDING"].to_i
    total   = campaign.emails.size
    [sent, failed, pending, total]
  end

  # Status label + tone for PAST table
  # SENT: all sent
  # FAILED: all failed (and none sent/pending)
  # PARTIAL: any mix (some sent, some failed/pending)
  def past_status_badge(campaign)
    sent, failed, pending, total = campaign_sent_counts(campaign)

    if total > 0 && sent == total
      ["SENT", "bg-emerald-500/15 text-emerald-200"]
    elsif total > 0 && sent.zero? && pending.zero? && failed == total
      ["FAILED", "bg-red-500/15 text-red-200"]
    else
      ["PARTIAL", "bg-amber-500/15 text-amber-200"]
    end
  end
end