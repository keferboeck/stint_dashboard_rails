if ENV["SECRET_KEY_BASE_DUMMY"] == "1"
  # Don’t validate API during image build
else
  MANDRILL_API_KEY = ENV["MANDRILL_API_KEY"]
  Rails.logger.warn("[mandrill] MANDRILL_API_KEY is missing") if MANDRILL_API_KEY.to_s.strip.empty?
end