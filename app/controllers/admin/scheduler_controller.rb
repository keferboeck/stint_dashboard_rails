# app/controllers/admin/scheduler_controller.rb
class Admin::SchedulerController < ActionController::Base
  # External services (cron websites) won’t have your CSRF token:
  protect_from_forgery with: :null_session

  before_action :require_token!
  before_action :ensure_cron_enabled!

  # GET/POST /admin/scheduler/run
  def run
    tz   = AppSetting.instance.timezone.presence || "Europe/London"
    now  = Time.find_zone(tz).now

    # Find campaigns due now (you already have the schema/columns)
    due = Campaign.where(status: "scheduled").where("scheduled_at <= ?", now)

    enqueued = 0
    failed   = 0

    due.find_each do |c|
      begin
        # Mark as queued and enqueue a job to actually process it
        c.update!(status: "queued")
        CronTickJob.perform_later(c.id)
        enqueued += 1
      rescue => e
        c.update(status: "failed", failure_reason: e.message)
        failed += 1
      end
    end

    render json: {
      ok: true,
      env: Rails.env,
      timezone: tz,
      now: now.iso8601,
      enqueued: enqueued,
      failed: failed
    }
  end

  private

  # Accept token via header or param. Different per-environment.
  def require_token!
    expected = ENV.fetch("CRON_TOKEN", "dev-only-token")
    provided = request.headers["X-Cron-Token"].presence || params[:token].to_s
    unless ActiveSupport::SecurityUtils.secure_compare(provided, expected)
      render json: { ok: false, error: "unauthorized" }, status: :unauthorized
    end
  end

  def ensure_cron_enabled!
    settings = AppSetting.instance
    unless settings.cron_enabled
      render json: { ok: false, error: "cron disabled" }, status: 423 # Locked
    end
  end
end