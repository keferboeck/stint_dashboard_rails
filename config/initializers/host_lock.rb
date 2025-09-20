Rails.application.configure do
  # Only accept the dashboard host
  config.hosts.clear
  config.hosts << "stint.keferboeck.com"

  # Generate URLs for the dashboard host
  Rails.application.routes.default_url_options[:host] = "stint.keferboeck.com"
  if defined?(ActionMailer)
    config.action_mailer.default_url_options = { host: "stint.keferboeck.com", protocol: "https" }
  end
end