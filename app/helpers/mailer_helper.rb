module MailerHelper
  def support_email
    ENV["SUPPORT_EMAIL"].presence || "georg@keferboeck.com"
  end
end