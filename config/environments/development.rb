require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
  end

  config.cache_store = :memory_store
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false

  # ✅ Single, canonical defaults for dev URLs
  config.force_ssl = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method    = :letter_opener_web
  config.action_mailer.default_url_options = {
    host: "localhost",
    port: 3000,
    protocol: "http"
  }
  Rails.application.routes.default_url_options = config.action_mailer.default_url_options

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_record.query_log_tags_enabled = true
  config.active_job.verbose_enqueue_logs = true
  config.action_view.annotate_rendered_view_with_filenames = true

  config.middleware.delete ActionDispatch::HostAuthorization

  config.action_controller.raise_on_missing_callback_actions = true

  config.hosts << "localhost"
  config.hosts << "127.0.0.1"
  config.hosts << "::1"
end