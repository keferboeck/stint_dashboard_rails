require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  config.ssl_options = { redirect: { exclude: ->(req) { req.path == "/up" } } }
  config.silence_healthcheck_path = "/up"

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Don’t boot the whole app for assets:precompile
  config.assets.initialize_on_precompile = false

  # Serve static assets
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present? || true

  # Make sure Propshaft can see Tailwind’s build output
  config.assets.paths << Rails.root.join("app/assets/builds")

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "dashboard.stint.co"),
    protocol: "https"
  }
  Rails.application.routes.default_url_options = config.action_mailer.default_url_options

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Serve files from /public (required when we commit precompiled assets)
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # We’re committing precompiled assets, so keep runtime compilation off
  config.assets.compile = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  # Deliver via Mandrill SMTP using only MANDRILL_API_KEY
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              "smtp.mandrillapp.com",
    port:                 587,
    user_name:            "mandrill",                 # Mandrill accepts any string or your account email
    password:             ENV["MANDRILL_API_KEY"],
    authentication:       :login,
    enable_starttls_auto: true
  }

  # Allow all ondigitalocean.app preview hosts (safe enough for this env)
  config.hosts << /\A.*\.ondigitalocean\.app\z/

  # (optional) if you also plan to use your domain:
  config.hosts << "dashboard.stint.co"
  config.hosts << "staging-rails-dashboard-u9jt9.ondigitalocean.app"
  config.hosts << "production-rails-dashboard-cb6sb.ondigitalocean.app"

  # TEMP while stabilizing:
  config.hosts.clear
  config.middleware.delete(ActionDispatch::HostAuthorization) rescue nil

  config.after_initialize do
    puts "ALLOWED HOSTS at boot: #{Rails.application.config.hosts.inspect}"
  end
end
