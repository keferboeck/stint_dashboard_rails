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
  end

  def create
    @user = User.new(user_params)
    # Generate a temporary password (device email can be added later)
    temp_password = SecureRandom.base58(16)
    @user.password = @user.password_confirmation = temp_password

    if @user.save
      flash[:notice] = "User created. Temporary password generated."
      redirect_to admin_users_path
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
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

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :role,
      :notify_all_new_schedules,
      :notify_all_sent_copies,
      :notify_all_campaign_summaries,
      :notify_own_new_schedules,
      :notify_own_sent_copies,
      :notify_own_campaign_summaries
    )
  end
end