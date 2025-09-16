class UserMailer < ApplicationMailer
  def admin_created(user_id, plain_password)
    @user = User.find(user_id)
    @plain_password = plain_password
    mail to: @user.email, subject: "Your Stint Dashboard account"
  end
end