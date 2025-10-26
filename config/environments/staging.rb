# config/environments/staging.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.assets.compile = false

  host = ENV.fetch("APP_HOST", "staging-rails-dashboard-u9jt9.ondigitalocean.app")
  protocol = ENV.fetch("APP_PROTOCOL", "https")
  config.action_mailer.default_url_options = { host:, protocol: }
  Rails.application.routes.default_url_options = config.action_mailer.default_url_options

  config.action_mailer.perform_deliveries = true
  # delivery_method stays as you configured (Mandrill/SMTP). Don’t enable LetterOpener here.

  config.log_level = :info
end