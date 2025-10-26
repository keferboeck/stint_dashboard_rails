Rails.application.configure do
  if Rails.env.production? || Rails.env.staging?
    # One canonical host per deployed env
    host = ENV.fetch("APP_HOST", "stint.keferboeck.com") # set per env
    protocol = ENV.fetch("APP_PROTOCOL", "https")

    config.hosts.clear
    config.hosts << host

    Rails.application.routes.default_url_options = { host: host, protocol: protocol }
    if defined?(ActionMailer)
      config.action_mailer.default_url_options = { host: host, protocol: protocol }
    end

  else
    # Development / test: allow local access + generate localhost URLs
    config.hosts.clear
    config.hosts += ["localhost", "127.0.0.1", "::1"]

    Rails.application.routes.default_url_options = { host: "localhost", port: 3000, protocol: "http" }
    if defined?(ActionMailer)
      config.action_mailer.default_url_options = { host: "localhost", port: 3000, protocol: "http" }
    end
  end
end