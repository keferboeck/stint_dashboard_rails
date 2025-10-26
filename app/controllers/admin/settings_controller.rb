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
      changed_keys = @settings.saved_changes.keys - %w[id created_at updated_at]
      notify_settings_updated!(changed_keys) if changed_keys.any?
      redirect_to admin_settings_path, notice: "Settings saved."
    else
      flash.now[:alert] = @settings.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  def hold_all_schedules
    @settings = AppSetting.instance
    @settings.update!(scheduling_on_hold: true)

    notify_event!(
      title:   "All schedules put on hold",
      message: "Scheduling has been paused by #{current_user.email}",
      severity: :warning
    )

    respond_to do |format|
      format.turbo_stream { render turbo_stream_replace_safety }
      format.html { redirect_to admin_settings_path, notice: "All schedules put on hold." }
    end
  end

  def purge_future_schedules
    unless params[:confirm] == "YES"
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = "Confirmation missing. Type YES to proceed."
          render turbo_stream_replace_safety
        end
        format.html { redirect_to admin_settings_path, alert: "Confirmation missing. Type YES to proceed." }
      end
      return
    end

    count = 0
    ActiveRecord::Base.transaction do
      Campaign.where("scheduled_at > ?", Time.current).find_each do |c|
        Email.where(campaign_id: c.id).delete_all
        c.destroy!
        count += 1
      end
    end

    notify_event!(
      title:   "Purged #{count} future campaign(s)",
      message: "#{current_user.email} deleted all campaigns scheduled after #{Time.zone.now}",
      severity: :critical
    )

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Purged #{count} future campaign(s)."
        render turbo_stream_replace_safety
      end
      format.html { redirect_to admin_settings_path, notice: "Purged #{count} future campaign(s)." }
    end
  end

  def toggle_cron
    @settings = AppSetting.instance
    @settings.update!(cron_enabled: !@settings.cron_enabled)
    state = @settings.cron_enabled ? "enabled" : "disabled"

    notify_event!(
      title:   "Cron #{state}",
      message: "Cron job execution was #{state} by #{current_user.email}",
      severity: @settings.cron_enabled ? :success : :warning
    )

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Cron #{state}."
        render turbo_stream_replace_safety
      end
      format.html { redirect_to admin_settings_path, notice: "Cron #{state}." }
    end
  end

  private

  def turbo_stream_replace_safety
    turbo_stream.replace(
      "safety_frame",
      partial: "admin/settings/safety",
      locals: { settings: @settings }
    )
  end

  def require_admin!
    redirect_to dashboard_path, alert: "Not authorized." unless current_user&.admin?
  end

  def settings_params
    params.require(:app_setting).permit(:timezone)
  end

  # --- notifications you already wired; no change to how emails are sent ---
  def notify_event!(title:, message:, severity: :info)
    recipients = admin_recipients_for_env
    return if recipients.empty?
    mail = AdminNoticeMailer.event(to: recipients, title: title, message: message, severity: severity)
    Rails.env.development? ? mail.deliver_now : mail.deliver_later
  end

  def notify_settings_updated!(changed_keys)
    recipients = admin_recipients_for_env
    return if recipients.empty?
    mail = AdminNoticeMailer.settings_updated(to: recipients, changed_keys: changed_keys, actor: current_user)
    Rails.env.development? ? mail.deliver_now : mail.deliver_later
  end

  def admin_recipients_for_env
    scope  = User.where(role: "admin")
    emails = Rails.env.development? ? scope.where("email ILIKE ?", "%@keferboeck.com").pluck(:email) : scope.pluck(:email)
    emails.uniq
  end
end