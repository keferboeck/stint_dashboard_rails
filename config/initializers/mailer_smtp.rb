# config/initializers/mailer_smtp.rb
Rails.application.configure do
  if ENV["MANDRILL_API_KEY"].present?
    config.action_mailer.perform_caching       = false
    config.action_mailer.perform_deliveries    = true
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method       = :smtp
    config.action_mailer.smtp_settings = {
      address:              "smtp.mandrillapp.com",
      port:                 587,
      user_name:            "mandrill", # any string or your Mandrill login email works
      password:             ENV["MANDRILL_API_KEY"],
      authentication:       :login,
      enable_starttls_auto: true
    }

    # sensible defaults for all mailers
    default_host = ENV.fetch("APP_HOST", "localhost")
    default_proto = Rails.env.development? ? "http" : "https"

    config.action_mailer.default_url_options = {
      host:     default_host,
      protocol: default_proto
    }
    Rails.application.routes.default_url_options = config.action_mailer.default_url_options
  end
end