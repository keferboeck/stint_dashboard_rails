module MailerHelper
  def support_email
    ENV.fetch("SUPPORT_EMAIL", "georg@keferboeck.com")
  end
end