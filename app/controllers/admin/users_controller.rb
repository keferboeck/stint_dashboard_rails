# app/controllers/admin/users_controller.rb
class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_user, only: %i[edit update]

  def index
    @users = User.order(:email)
  end

  def new
    @user = User.new(role: "viewer")
    # Optional server side defaults for a brand new staff user
    # if params.dig(:user, :role) == "staff" || @user.role == "staff"
    #   @user.assign_attributes(
    #     notify_new_scheduled_mine: true,
    #     notify_copy_mine:          true,
    #     notify_summary_mine:       true
    #   )
    # end
  end

  # app/controllers/admin/users_controller.rb
  def create
    @user = User.new(user_params)

    # temporary password so Devise validations pass
    temp_password = Devise.friendly_token.first(16)
    @user.password = @user.password_confirmation = temp_password

    enforce_notification_permissions(@user) if respond_to?(:enforce_notification_permissions, true)

    if @user.save
      # Generate Devise reset token for the user
      raw_token = @user.send(:set_reset_password_token)

      # Send welcome + reset email via the shared layout
      begin
        UserWelcomeMailer.welcome(user: @user, reset_token: raw_token).deliver_later
        flash[:notice] = "User created. Welcome email sent with password reset link."
      rescue => e
        Rails.logger.error("[user_welcome_mailer] #{e.class}: #{e.message}")
        flash[:alert] = "User created, but sending the welcome email failed: #{e.message}"
      end

      redirect_to admin_users_path
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    # Assign first, then enforce permissions, then save
    @user.assign_attributes(user_params)
    enforce_notification_permissions(@user)

    if @user.save
      flash[:notice] = "User updated."
      redirect_to admin_users_path
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def require_admin!
    return if current_user&.admin?
    redirect_to dashboard_path, alert: "Not authorized."
  end

  # Always permit all flags. We will zero out disallowed ones based on the final role.
  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :role, :preferred_time_zone,
      :notify_new_scheduled_all, :notify_copy_all, :notify_summary_all,
      :notify_new_scheduled_mine, :notify_copy_mine, :notify_summary_mine
    )
  end

  # Normalize flags according to the effective role (param wins over current)
  def enforce_notification_permissions(user)
    effective_role = user.role.presence || "viewer"

    case effective_role
    when "admin"
      # allowed: all six flags, do nothing
    when "staff"
      user.notify_new_scheduled_all = false
      user.notify_copy_all          = false
      user.notify_summary_all       = false
      # mine flags allowed as submitted
    else # viewer
      user.notify_new_scheduled_all = false
      user.notify_copy_all          = false
      user.notify_summary_all       = false
      user.notify_new_scheduled_mine = false
      user.notify_copy_mine          = false
      user.notify_summary_mine       = false
    end
  end
end