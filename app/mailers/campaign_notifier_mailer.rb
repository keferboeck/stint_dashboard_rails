# app/mailers/campaign_notifier_mailer.rb
class CampaignNotifierMailer < ApplicationMailer
  default from: ENV.fetch("OUTBOUND_FROM_EMAIL", "no-reply@stint.co")

  layout "stint_mailer" # uses the same layout you already have for MJML templates

  # --- (A) & (D): New campaign created/scheduled ---
  def new_campaign(campaign, recipient)
    @campaign = campaign
    @user     = recipient
    @creator  = campaign.user
    @title    = "New campaign scheduled"
    @summary  = "A new campaign has been created and scheduled."

    mail(
      to: @user.email,
      subject: "[Dashboard] New campaign scheduled – #{@campaign.subject}"
    )
  end

  # --- (B) & (E): Copy of a sent campaign (admin or own) ---
  def copy_sent(campaign, recipient)
    @campaign = campaign
    @user     = recipient
    @creator  = campaign.user
    @title    = "Campaign copy sent"
    @summary  = "A campaign has been sent. Here's a copy of the details."

    mail(
      to: @user.email,
      subject: "[Dashboard] Campaign sent – #{@campaign.subject}"
    )
  end

  # --- (C) & (F): Summary after run (admin or own) ---
  def summary_after_run(campaign, recipient)
    @campaign = campaign
    @user     = recipient
    @creator  = campaign.user
    sent      = campaign.emails.where(status: "SENT").count
    failed    = campaign.emails.where(status: "FAILED").count

    @title   = "Campaign summary"
    @summary = "The campaign has finished sending."

    @stats = {
      total: campaign.emails.count,
      sent:  sent,
      failed: failed
    }

    mail(
      to: @user.email,
      subject: "[Dashboard] Campaign summary – #{@campaign.subject}"
    )
  end
end