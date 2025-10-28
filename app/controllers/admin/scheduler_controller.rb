# app/controllers/admin/scheduler_controller.rb
class Admin::SchedulerController < ApplicationController
  # This endpoint is called by your DO cron/worker via curl.
  # It must be CSRF-exempt and auth-less, guarded by a token.
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  # POST /admin/scheduler/run?token=...
  # GET  /admin/scheduler/run?token=...
  def run
    unless valid_token?(params[:token])
      Rails.logger.warn("[scheduler#run] invalid token")
      return render plain: "forbidden", status: :forbidden
    end

    settings = AppSetting.instance

    if settings.scheduling_on_hold
      Rails.logger.info("[scheduler#run] scheduling_on_hold=TRUE — skip")
      return render json: { ok: true, held: true, cron_enabled: settings.cron_enabled, picked: 0 }
    end

    unless settings.cron_enabled
      Rails.logger.info("[scheduler#run] cron_enabled=FALSE — skip")
      return render json: { ok: true, held: false, cron_enabled: false, picked: 0 }
    end

    now = Time.current
    due_scope = Campaign.where(status: "SCHEDULED").where("scheduled_at <= ?", now)
    due_ids   = due_scope.limit(200).pluck(:id) # hard cap to avoid stampede

    picked = 0
    due_ids.each do |cid|
      CronTickJob.perform_later(cid)
      picked += 1
    end

    Rails.logger.info("[scheduler#run] enqueued=#{picked}")
    render json: { ok: true, held: false, cron_enabled: true, picked: picked, at: now.utc }
  rescue => e
    Rails.logger.error("[scheduler#run] ERROR #{e.class}: #{e.message}")
    render json: { ok: false, error: "#{e.class}: #{e.message}" }, status: :internal_server_error
  end

  private

  def valid_token?(token)
    return false if token.blank?

    # Use CRON_TOKEN in all envs. In development also allow a fixed dev token.
    expected = ENV["CRON_TOKEN"].to_s
    return true if expected.present? && ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected)

    Rails.env.development? && token == "dev-only-token"
  end
end