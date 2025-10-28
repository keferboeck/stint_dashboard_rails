# config/initializers/host_allowlist.rb
Rails.application.configure do
  # Start clean and add exactly what we expect
  config.hosts.clear

  app_env = ENV.fetch("APP_ENV", Rails.env) # e.g. "staging" while RAILS_ENV is "production"

  # Known hosts
  base_hosts = %w[
    localhost
    127.0.0.1
    dashboard.stint.co
    staging-rails-dashboard-u9jt9.ondigitalocean.app
  ]

  base_hosts.each { |h| config.hosts << h }

  # Allow any *.ondigitalocean.app (preview and app platform hosts)
  config.hosts << /\A.*\.ondigitalocean\.app\z/

  # If an explicit host is provided, allow it too
  config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?

  # -------- Default URL options (used by URL helpers and mailers) --------
  host_for_urls =
    if ENV["APP_HOST"].present?
      ENV["APP_HOST"]
    else
      case
      when Rails.env.development?
        "localhost:3000"
      when app_env.to_s == "staging"
        "staging-rails-dashboard-u9jt9.ondigitalocean.app"
      else
        "dashboard.stint.co"
      end
    end

  protocol_for_urls = Rails.env.development? ? "http" : "https"

  Rails.application.routes.default_url_options[:host] = host_for_urls

  if defined?(ActionMailer)
    config.action_mailer.default_url_options = {
      host:     host_for_urls,
      protocol: protocol_for_urls
    }
  end
end