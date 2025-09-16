# frozen_string_literal: true
class Admin::SchedulerController < ApplicationController
  skip_before_action :verify_authenticity_token
  # This endpoint is machine-to-machine. We don't require a signed-in user,
  # we protect it with a token instead:
  skip_before_action :authenticate_user!

  before_action :check_token!

  def run
    # Call your guarded processor (it already respects AppSetting flags)
    Scheduler::ProcessScheduledCampaigns.call
    render json: { ok: true }, status: :ok
  end

  private

  def check_token!
    expected = ENV.fetch("SCHEDULER_TOKEN")
    provided = params[:token].to_s
    unless ActiveSupport::SecurityUtils.secure_compare(provided, expected)
      head :unauthorized
    end
  end
end