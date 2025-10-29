# app/mailers/campaign_notifier_mailer.rb
class CampaignNotifierMailer < ApplicationMailer
  default from: ENV.fetch("OUTBOUND_FROM_EMAIL", "no-reply@stint.co")
  layout "stint_mailer"

  # --- (A) & (D): New campaign created/scheduled ---
  def new_campaign(campaign, recipient)
    @campaign = campaign
    @user     = recipient
    @creator  = campaign.user
    @title    = "🟢 New campaign scheduled"
    @summary  = "A new campaign has been created and scheduled by #{@creator&.first_name || 'a team member'}."

    mail(
      to: @user.email,
      subject: "🟢 New campaign scheduled – #{@campaign.subject}"
    )
  end

  # --- (B) & (E): Copy of a sent campaign (always green) ---
  def copy_sent(campaign, recipient)
    @campaign = campaign
    @user     = recipient
    @creator  = campaign.user
    @title    = "🟢 Campaign sent"
    @summary  = "A campaign has just been sent. Here’s a copy of the details."

    mail(
      to: @user.email,
      subject: "🟢 Campaign sent – #{@campaign.subject}"
    )
  end

  # --- (C) & (F): Summary after run (colour depends on results) ---
  def summary_after_run(campaign, recipient)
    @campaign = campaign
    @user     = recipient
    @creator  = campaign.user

    total  = campaign.emails.count
    sent   = campaign.emails.where(status: "SENT").count
    failed = campaign.emails.where(status: "FAILED").count

    emoji =
      if total > 0 && sent == total
        "🟢"     # all sent
      elsif total > 0 && sent.zero?
        "🔴"     # all failed
      else
        "🟡"     # partial
      end

    @title   = "#{emoji} Campaign summary"
    @summary = "The campaign has finished sending."
    @stats   = { total: total, sent: sent, failed: failed }

    mail(
      to: @user.email,
      subject: "#{emoji} Campaign summary – #{@campaign.subject}"
    )
  end
end