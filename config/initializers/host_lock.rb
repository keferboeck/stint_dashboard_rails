# config/initializers/host_lock.rb
Rails.application.configure do
  config.hosts.clear

  case Rails.env
  when "production"
    host = "stint.keferboeck.com"
  when "staging"
    host = "staging-rails-dashboard-u9jt9.ondigitalocean.app"
  else
    host = "localhost"
  end

  config.hosts << host
  Rails.application.routes.default_url_options[:host] = host

  if defined?(ActionMailer)
    protocol = Rails.env.development? ? "http" : "https"
    config.action_mailer.default_url_options = { host:, protocol: }
  end
end