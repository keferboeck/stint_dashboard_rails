# config/initializers/mandrill.rb
MANDRILL_API_KEY = ENV["MANDRILL_API_KEY"]
Rails.logger.warn("[mandrill] MANDRILL_API_KEY is missing") if MANDRILL_API_KEY.blank?