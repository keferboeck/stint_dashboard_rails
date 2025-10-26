# Make sure the delivery method exists and is selected
require "letter_opener_web"

ActionMailer::Base.add_delivery_method(:letter_opener_web, LetterOpenerWeb::DeliveryMethod)

Rails.application.configure do
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method    = :letter_opener_web
  config.action_mailer.default_url_options ||= {}
  config.action_mailer.default_url_options[:host] ||= "localhost"
  config.action_mailer.default_url_options[:port] ||= 3000
end

# Optional: tell letter_opener_web where to read from (default is tmp/letter_opener)
LetterOpenerWeb.configure do |config|
  config.letters_location = Rails.root.join("tmp", "letter_opener")
end