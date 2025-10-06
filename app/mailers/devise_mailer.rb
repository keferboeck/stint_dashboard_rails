class DeviseMailer < Devise::Mailer
  helper :application
  layout 'mailer'

  def reset_password_instructions(record, token, opts = {})
    @token_url = edit_password_url(record, reset_password_token: token)
    super
  end
end