# config/initializers/host_allowlist.rb
Rails.application.configure do
  # One place to manage allowed hosts + default URL options.
  config.hosts.clear

  # Always safe to allow these:
  %w[
    localhost
    127.0.0.1
    dashboard.stint.co
    staging-rails-dashboard-u9jt9.ondigitalocean.app
  ].each { |h| config.hosts << h }

  # Allow any *.ondigitalocean.app (preview/staging app platform hosts)
  config.hosts << /\A.*\.ondigitalocean\.app\z/

  # If APP_HOST is set, allow it explicitly
  config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?

  # ----- Default URL options for URL helpers + mailers -----
  host_for_urls =
    if ENV["APP_HOST"].present?
      ENV["APP_HOST"]
    elsif Rails.env.development?
      "localhost:3000"
    else
      "dashboard.stint.co" # fallback for production-like envs
    end

  protocol_for_urls = Rails.env.development? ? "http" : "https"

  Rails.application.routes.default_url_options[:host] = host_for_urls
  if defined?(ActionMailer)
    config.action_mailer.default_url_options = { host: host_for_urls, protocol: protocol_for_urls }
  end
end