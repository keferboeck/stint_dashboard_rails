# app/controllers/admin/campaigns_controller.rb
class Admin::CampaignsController < ApplicationController
  before_action :require_manager_or_admin!, only: [:new, :create, :reschedule, :send_now, :destroy]
  before_action :set_campaign, only: [:show, :reschedule, :send_now, :destroy]

  def index
    now = Time.current

    @scheduled = Campaign
                   .where(status: "SCHEDULED")
                   .where("scheduled_at IS NOT NULL AND scheduled_at > ?", now)
                   .order(:scheduled_at)

    @due = Campaign
             .where(status: "SCHEDULED")
             .where("scheduled_at IS NOT NULL AND scheduled_at <= ?", now)
             .order(:scheduled_at)

    @past = Campaign
              .where.not(status: "SCHEDULED")
              .order(Arel.sql("COALESCE(scheduled_at, created_at) DESC"))
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @campaign.as_json(include: :emails) }
    end
  end

  # ---- Buttons on show page ----

  def reschedule
    local = params[:scheduled_at_local].to_s.strip
    if local.blank?
      return redirect_to admin_campaign_path(@campaign), alert: "Choose a date and time."
    end

    @campaign.update!(
      scheduled_at: parse_london_wall_to_utc(local),
      status: "SCHEDULED"
    )

    human = @campaign.scheduled_at.in_time_zone("Europe/London").strftime("%Y-%m-%d %H:%M")
    redirect_to admin_campaign_path(@campaign), notice: "Rescheduled for #{human}."
  rescue => e
    redirect_to admin_campaign_path(@campaign), alert: "Reschedule failed: #{e.message}"
  end

  def send_now
    # Make sure it looks like an immediate run to the scheduler
    @campaign.update!(scheduled_at: Time.current.utc, status: "SCHEDULED") if @campaign.scheduled_at.nil?

    # Use the job you actually have wired
    CronTickJob.perform_later(@campaign.id)

    redirect_to admin_campaign_path(@campaign), notice: "Send now queued."
  rescue => e
    redirect_to admin_campaign_path(@campaign), alert: "Could not enqueue: #{e.message}"
  end

  def destroy
    @campaign.destroy!
    redirect_to admin_campaigns_path, notice: "Campaign deleted."
  rescue => e
    redirect_to admin_campaign_path(@campaign), alert: "Delete failed: #{e.message}"
  end

  # ---- legacy JSON create (unchanged) ----
  def create
    utc_instant = params[:scheduled_at_local].present? ? parse_london_wall_to_utc(params[:scheduled_at_local]) : nil

    c = Campaign.new(
      name:          params[:name],
      template_name: params[:template_name],
      subject:       params[:subject],
      preview_text:  params[:preview_text],
      scheduled_at:  utc_instant,
      status:        'SCHEDULED',
      user:          current_user
    )

    if params[:emails].is_a?(Array)
      params[:emails].each do |e|
        c.emails.build(address: e[:address], custom_fields: e[:custom_fields], status: 'PENDING')
      end
    end

    if c.save
      render json: { id: c.id, message: 'Campaign scheduled' }, status: :created
    else
      render json: { error: c.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:id])
  end

  def parse_london_wall_to_utc(local_s)
    y, m, rest = local_s.split('-')
    d, hm = rest.split('T')
    h, min = hm.split(':')
    Time.use_zone('Europe/London') { Time.zone.local(y, m, d, h, min).utc }
  end
end