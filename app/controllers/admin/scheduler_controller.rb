# app/controllers/admin/scheduler_controller.rb
class Admin::SchedulerController < ApplicationController
  # Called by DO cron via curl. CSRF-exempt + auth-less, guarded by token.
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  # POST /admin/scheduler/run?token=...
  # GET  /admin/scheduler/run?token=...
  def run
    unless valid_token?(params[:token])
      Rails.logger.warn("[scheduler#run] invalid token")
      return render plain: "forbidden", status: :forbidden
    end

    # ---- Sentry Cron: start check-in (no-op if not configured)
    check_in_id = sentry_check_in_start!

    settings = AppSetting.instance

    if settings.scheduling_on_hold
      Rails.logger.info("[scheduler#run] scheduling_on_hold=TRUE — skip")
      return finish_ok(check_in_id, picked: 0, held: true, cron: settings.cron_enabled)
    end

    unless settings.cron_enabled
      Rails.logger.info("[scheduler#run] cron_enabled=FALSE — skip")
      return finish_ok(check_in_id, picked: 0, held: false, cron: false)
    end

    now      = Time.current
    due_ids  = Campaign.where(status: "SCHEDULED").where("scheduled_at <= ?", now)
                       .limit(200).pluck(:id) # hard cap to avoid stampede

    picked = 0
    due_ids.each do |cid|
      CronTickJob.perform_later(cid)
      picked += 1
    end

    Rails.logger.info("[scheduler#run] enqueued=#{picked}")
    finish_ok(check_in_id, picked: picked, held: false, cron: true, at: now.utc)
  rescue => e
    Rails.logger.error("[scheduler#run] ERROR #{e.class}: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
    sentry_check_in_finish!(check_in_id, :error)
    render json: { ok: false, error: "#{e.class}: #{e.message}" }, status: :internal_server_error
  end

  private

  def valid_token?(token)
    return false if token.blank?

    expected = ENV["CRON_TOKEN"].to_s
    return true if expected.present? &&
      ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected)

    Rails.env.development? && token == "dev-only-token"
  end

  # ---------- Sentry helpers (safe no-ops if not configured) ----------

  # Start a Sentry Cron check-in and return check_in_id (or nil).
  def sentry_check_in_start!
    return nil unless defined?(Sentry)

    slug = ENV["SENTRY_CRON_MONITOR_SLUG"].presence
    return nil unless slug # skip quietly if not set

    # DO cron = every 15 min; small margin; reasonable max runtime.
    monitor_config = Sentry::Cron::MonitorConfig.from_interval(
      15, :minute,
      checkin_margin: 5,
      max_runtime: 10,
      timezone: "Europe/Vienna"
    )

    Sentry.capture_check_in(slug, :in_progress, monitor_config: monitor_config)
  rescue => e
    Rails.logger.warn "[sentry-cron] start check-in failed: #{e.class}: #{e.message}"
    nil
  end

  # Finish the check-in with :ok or :error.
  def sentry_check_in_finish!(check_in_id, status)
    return unless defined?(Sentry)

    slug = ENV["SENTRY_CRON_MONITOR_SLUG"].presence
    return unless slug

    if check_in_id
      Sentry.capture_check_in(slug, status, check_in_id: check_in_id)
    else
      Sentry.capture_check_in(slug, status)
    end
  rescue => e
    Rails.logger.warn "[sentry-cron] finish check-in failed: #{e.class}: #{e.message}"
  end

  # Common OK exit that also closes the Sentry check-in.
  def finish_ok(check_in_id, picked:, held:, cron:, at: Time.current.utc)
    sentry_check_in_finish!(check_in_id, :ok)
    render json: { ok: true, held: held, cron_enabled: cron, picked: picked, at: at }
  end
end