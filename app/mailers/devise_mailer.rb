class DeviseMailer < Devise::Mailer
  helper :application, :mailer
  include Devise::Controllers::UrlHelpers
  layout "stint_mailer"

  def reset_password_instructions(record, token, opts = {})
    @title       = "Reset your password"
    @heading     = "Reset your password"
    @reset_url   = edit_user_password_url(reset_password_token: token)
    @utm_term    = "footer"
    @utm_content = "reset-password"
    super
  end
end