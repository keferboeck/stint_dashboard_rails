class DeviseMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers
  def reset_password_instructions(record, token, opts = {})
    @reset_url = edit_user_password_url(reset_password_token: token)
    super
  end
end