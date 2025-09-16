class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  helper_method :role?, :admin?, :manager?, :viewer?

  # Flexible role check (works with enum helpers or a plain string column)
  def role?(name)
    return false unless current_user
    helper = "role_#{name}?"
    if current_user.respond_to?(helper)
      current_user.public_send(helper)
    else
      current_user.role.to_s == name.to_s
    end
  end

  def admin?
    role?(:admin)
  end

  def manager?
    role?(:manager)
  end

  def viewer?
    role?(:viewer)
  end

  # --- Guards usable in any controller ---

  def require_admin!
    return if admin?
    deny_access!
  end

  def require_manager_or_admin!
    return if admin? || manager?
    deny_access!
  end

  def require_viewer_or_higher!
    return if admin? || manager? || viewer?
    deny_access!
  end

  private

  def deny_access!
    respond_to do |format|
      format.html { redirect_to authenticated_root_path, alert: "You do not have permission to perform that action." }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end

  def after_sign_in_path_for(_resource)
    dashboard_path
  end
end