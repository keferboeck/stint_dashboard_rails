# app/controllers/admin/settings_controller.rb
class Admin::SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def show
    @settings = AppSetting.instance
  end

  def update
    @settings = AppSetting.instance
    if @settings.update(settings_params)
      notify_event!(:settings_updated, "Settings saved", icon: :black)
      redirect_to admin_settings_path, notice: "Settings saved."
    else
      flash.now[:alert] = @settings.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  # app/controllers/admin/settings_controller.rb
  def hold_all_schedules
    @settings = AppSetting.instance
    was_on_hold = @settings.scheduling_on_hold
    @settings.update!(scheduling_on_hold: !was_on_hold)

    # email
    tz      = @settings.timezone.presence || "Europe/London"
    when_str = Time.current.in_time_zone(tz).strftime("%A, %d %B  %Y at %H:%M %Z")
    on      = @settings.scheduling_on_hold
    title   = on ? "Schedules put on hold" : "Schedules released"
    severity = on ? :warning : :success
    message = "#{title} by #{current_user.email} at #{when_str}."

    AdminNoticeMailer.event(
      to: admin_recipients_for_env,
      title: title,
      message: message,
      severity: severity
    ).deliver_later

    respond_to do |format|
      if request.format.turbo_stream?
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "admin_settings_safety",
            partial: "admin/settings/safety",
            locals: { settings: @settings }
          )
        end
      else
        format.html { redirect_to admin_settings_path, notice: title }
      end
    end
  end

  # app/controllers/admin/settings_controller.rb
  def purge_future_schedules
    # require the guard confirmation
    unless params[:confirm].to_s == "YES"
      redirect_to admin_settings_path, alert: "Confirmation missing. Type YES to proceed."
      return
    end

    now = Time.current
    future_campaigns   = Campaign.where("scheduled_at > ?", now)
    future_email_scope = Email.where(campaign_id: future_campaigns.select(:id))

    counts = {
      campaigns: future_campaigns.count,
      emails:    future_email_scope.count
    }

    ActiveRecord::Base.transaction do
      future_email_scope.delete_all
      future_campaigns.find_each(&:destroy!) # keep callbacks if any
    end

    # single, dedicated email for purge (no duplicates, no event mail)
    AdminNoticeMailer.purge_future(
      to:     admin_recipients_for_env,
      counts: counts,
      actor:  current_user.email,
      at:     Time.current
    ).deliver_later

    redirect_to admin_settings_path,
                notice: "Purged #{counts[:campaigns]} future campaign(s) and #{counts[:emails]} pending email(s)."

  rescue => e
    Rails.logger.error("[purge_future_schedules] #{e.class}: #{e.message}")
    redirect_to admin_settings_path, alert: "Failed to purge future schedules: #{e.message}"
  end

  def toggle_cron
    s = AppSetting.instance
    new_state = !s.cron_enabled
    s.update!(cron_enabled: new_state)

    tz      = s.timezone.presence || "Europe/London"
    title   = new_state ? "Cron enabled" : "Cron disabled"   # ← no dot here
    message = "Cron runner has been #{new_state ? 'enabled' : 'disabled'} by #{current_user.email} at #{Time.current.in_time_zone(tz)}."
    severity = new_state ? :success : :info

    notify_event!(title: title, message: message, severity: severity)

    redirect_to admin_settings_path, notice: (new_state ? "Cron enabled." : "Cron disabled.")
  end

  private

  def require_admin!
    redirect_to dashboard_path, alert: "Not authorized." unless current_user&.admin?
  end

  def settings_params
    params.require(:app_setting).permit(:timezone)
  end

  def notify_event!(title:, message:, severity: :info)
    recipients = admin_recipients_for_env
    return if recipients.blank?

    AdminNoticeMailer.event(
      to: recipients,              # mailer will handle array or string
      title: title,                # ← plain title, no emoji
      message: message,
      severity: severity
    ).deliver_later
  end

  def admin_recipients_for_env
    emails = User.where(role: "admin").pluck(:email)
    if Rails.env.development?
      emails = emails.select { |e| e.ends_with?("@keferboeck.com") }
    end
    emails.presence || [ENV.fetch("FALLBACK_ADMIN_EMAIL", "georg@keferboeck.com")]
  end

  def notify_settings_updated!(changed_keys)
    recipients = admin_recipients_for_env
    return if recipients.empty?
    mail = AdminNoticeMailer.settings_updated(to: recipients, changed_keys: changed_keys, actor: current_user)
    Rails.env.development? ? mail.deliver_now : mail.deliver_later
  end
end