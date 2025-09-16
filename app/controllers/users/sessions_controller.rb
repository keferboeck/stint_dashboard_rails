# app/controllers/users/sessions_controller.rb
module Users
  class SessionsController < Devise::SessionsController
    # Where to go after successful login
    def after_sign_in_path_for(_resource)
      dashboard_path
    end

    # Where to go after logout
    def after_sign_out_path_for(_resource_or_scope)
      unauthenticated_root_path
    end
  end
end