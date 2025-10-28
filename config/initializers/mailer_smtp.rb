# config/initializers/mailer_smtp.rb
Rails.application.configure do
  next unless ENV["MANDRILL_API_KEY"].present?

  config.action_mailer.perform_caching       = false
  config.action_mailer.perform_deliveries    = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method       = :smtp
  config.action_mailer.smtp_settings = {
    address:              "smtp.mandrillapp.com",
    port:                 587,
    user_name:            "mandrill",
    password:             ENV["MANDRILL_API_KEY"],
    authentication:       :login,
    enable_starttls_auto: true
  }
end