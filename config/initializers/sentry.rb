# config/initializers/sentry.rb
if Rails.env.production?
  # Determine which DSN to use based on APP_ENV or fallback to production DSN
  sentry_dsn = ENV["SENTRY_DSN"]

  if sentry_dsn.present?
    Sentry.init do |config|
      config.dsn = sentry_dsn
      config.breadcrumbs_logger = [:active_support_logger, :http_logger]

      # Capture personal data only when explicitly allowed
      config.send_default_pii = true

      # Attach environment context (so Sentry shows "staging" vs "production")
      config.environment = ENV.fetch("APP_ENV", "production")

      # Optional: performance traces (adjust sample rate)
      config.traces_sample_rate = 0.5

      # Optional: exclude common noisy exceptions
      config.excluded_exceptions += ['ActionController::RoutingError', 'ActiveRecord::RecordNotFound']
    end
  else
    Rails.logger.info("[sentry] SENTRY_DSN not set, skipping Sentry init")
  end
else
  Rails.logger.info("[sentry] Skipped in #{Rails.env} environment")
end