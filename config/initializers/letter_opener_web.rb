# config/initializers/letter_opener_web.rb
if Rails.env.development?
  require "letter_opener_web"
  ActionMailer::Base.add_delivery_method(:letter_opener_web, LetterOpenerWeb::DeliveryMethod)

  Rails.application.configure do
    config.action_mailer.perform_deliveries = true
    config.action_mailer.delivery_method    = :letter_opener_web
    config.action_mailer.default_url_options ||= {}
    config.action_mailer.default_url_options[:host] ||= "localhost"
    config.action_mailer.default_url_options[:port] ||= 3000
    config.action_mailer.default_url_options[:protocol] ||= "http"
  end
end