# app/controllers/users/passwords_controller.rb
module Users
  class PasswordsController < Devise::PasswordsController
    # Optional: after password reset, send them to login
    def after_resetting_password_path_for(_resource)
      unauthenticated_root_path
    end
  end
end