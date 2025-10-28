# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # --- Boot & code loading ---
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  # --- Caching & logging ---
  config.action_controller.perform_caching = true
  config.log_tags = [:request_id]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.active_support.report_deprecations = false

  # --- SSL / Proxy ---
  config.assume_ssl = true
  config.force_ssl  = true
  # Skip http->https redirect for health checks
  config.ssl_options = { redirect: { exclude: ->(req) { req.path == "/up" } } }
  config.silence_healthcheck_path = "/up"

  # --- Assets / Static files ---
  # We commit precompiled assets. Do not init the app during precompile.
  config.assets.initialize_on_precompile = false
  config.assets.compile = false

  # Ensure Propshaft sees Tailwind build output
  config.assets.paths << Rails.root.join("app/assets/builds")

  # Serve /public (App Platform can serve these efficiently)
  config.public_file_server.enabled = true
  # Far-future caching for fingerprinted assets
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # --- Host & URL setup (APP_ENV-aware) ---
  app_env = ENV.fetch("APP_ENV", "production")

  default_host =
    if ENV["APP_HOST"].present?
      ENV["APP_HOST"]
    elsif app_env == "staging"
      "staging-rails-dashboard-u9jt9.ondigitalocean.app"
    else
      "dashboard.stint.co"
    end

  # URLs generated in mailers and helpers
  config.action_mailer.default_url_options = { host: default_host, protocol: "https" }
  Rails.application.routes.default_url_options = config.action_mailer.default_url_options

  # Strict host allow-list (also allow ondigitalocean.app previews)
  config.hosts << default_host
  config.hosts << /\A.*\.ondigitalocean\.app\z/


  # --- I18n ---
  config.i18n.fallbacks = true

  # --- Active Record ---
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]
end