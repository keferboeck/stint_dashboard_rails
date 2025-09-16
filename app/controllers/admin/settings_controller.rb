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
      redirect_to admin_settings_path, notice: "Settings saved."
    else
      flash.now[:alert] = @settings.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  # Safety: put all schedules on hold (no sending happens)
  def hold_all_schedules
    s = AppSetting.instance
    s.update!(scheduling_on_hold: true)
    redirect_to admin_settings_path, notice: "All schedules put on hold."
  end

  # Safety: delete future scheduled campaigns + their pending emails
  def purge_future_schedules
    # ASK TWICE on the UI — this action expects a POST with a confirmation param
    if params[:confirm] != "YES"
      redirect_to admin_settings_path, alert: "Confirmation missing. Type YES to proceed."
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
    redirect_to admin_settings_path, notice: "Purged #{count} future campaign(s)."
  end

  # Safety: stop/start cron without redeploy
  def toggle_cron
    s = AppSetting.instance
    s.update!(cron_enabled: !s.cron_enabled)
    msg = s.cron_enabled ? "Cron enabled." : "Cron disabled."
    redirect_to admin_settings_path, notice: msg
  end

  private

  def require_admin!
    return if current_user&.admin?
    redirect_to dashboard_path, alert: "Not authorized."
  end

  def settings_params
    params.require(:app_setting).permit(:timezone)
  end
end