class Admin::UsersController < ApplicationController
  before_action :require_admin!

  def new
    # build later if you add a form; for now can return JSON or render a view
  end

  def create
    permitted = params.permit(:first_name, :last_name, :position, :email, :role)
    role = (permitted[:role].presence || "viewer").to_s

    unless %w[admin manager viewer].include?(role)
      return render json: { error: "invalid role" }, status: :unprocessable_entity
    end

    temp_password = SecureRandom.base58(14)

    user = User.new(
      first_name: permitted[:first_name],
      last_name:  permitted[:last_name],
      position:   permitted[:position],
      email:      permitted[:email],
      role:       role,
      password:   temp_password,
      password_confirmation: temp_password
    )

    if user.save
      # Send “admin created your account” email (deliver_later uses your configured adapters)
      UserMailer.admin_created(user.id, temp_password).deliver_later
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: "User created and email sent." }
        format.json { render json: { id: user.id, email: user.email }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to dashboard_path, alert: user.errors.full_messages.to_sentence }
        format.json { render json: { error: user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
end