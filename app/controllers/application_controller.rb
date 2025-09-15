class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!

  # Render JSON on unauthorised admin access
  def require_admin!
    return if current_user&.role_admin?

    respond_to do |format|
      format.html { redirect_to root_path, alert: "You do not have access." }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end
end
