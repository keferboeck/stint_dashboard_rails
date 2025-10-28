# app/mailers/user_welcome_mailer.rb
class UserWelcomeMailer < ApplicationMailer
  layout "stint_mailer"

  ALLOWED_DOMAINS_NON_PROD = %w[stint.co keferboeck.com].freeze

  def welcome(user:, reset_token:)
    @user = user

    # Friendly tone in British English
    @heading      = "Welcome to Stint Dashboard"
    @message      = <<~MSG.strip
      Hello #{@user.first_name.presence || @user.email.split('@').first.capitalize},

      Your account has been set up successfully. 
      Stint Dashboard helps you manage campaigns, emails, and performance data with ease. 

      To get started, simply choose a password for your account below.
    MSG

    @button_label = "Set up your password"
    @button_url   = edit_user_password_url(reset_password_token: reset_token)

    # Footer UTM (for analytics consistency)
    @utm_term     = "footer"
    @utm_content  = "welcome"

    mail(to: safe_recipient(@user.email), subject: "Welcome to Stint Dashboard")
  end

  private

  def safe_recipient(email)
    return email if Rails.env.production?
    domain = email.to_s.split("@").last
    return email if ALLOWED_DOMAINS_NON_PROD.include?(domain)
    "georg@keferboeck.com"
  end
end