# Load all production defaults, then override only what you need.
require_relative "production"

Rails.application.configure do
  # Things you might want different on staging:
  # Show full error pages on staging (optional)
  # config.consider_all_requests_local = true

  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "staging-rails-dashboard-u9jt9.ondigitalocean.app"),
    protocol: "https"
  }
  Rails.application.routes.default_url_options = config.action_mailer.default_url_options

  # Add your staging host (keep whatever mechanism you already use for hosts)
  config.hosts << ENV.fetch("STAGING_HOST", "https://staging-rails-dashboard-u9jt9.ondigitalocean.app/")

  # Example: quieter logs, or keep same as production
  # config.log_level = :info
end