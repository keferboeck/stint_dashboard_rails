class Admin::CampaignsController < ApplicationController
  def index
    @future = Campaign.where(status: 'SCHEDULED').order(:scheduled_at)
    @past   = Campaign.where(status: %w[SENT FAILED]).order(scheduled_at: :desc)
    render json: { future: @future, past: @past }
  end

  def new
    render json: { ok: true, hint: 'POST to /admin/campaigns with fields' }
  end

  def create
    # expected params:
    # name, template_name, subject, preview_text, scheduled_at_local ("YYYY-MM-DDTHH:MM"), emails: [{ address, custom_fields }]
    utc_instant = parse_london_wall_to_utc(params[:scheduled_at_local]) if params[:scheduled_at_local].present?

    c = Campaign.new(
      name:          params[:name],
      template_name: params[:template_name],
      subject:       params[:subject],
      preview_text:  params[:preview_text],
      scheduled_at:  utc_instant,
      status:        'SCHEDULED'
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

  def reschedule
    c = Campaign.find(params[:id])
    local = params[:scheduled_at_local]
    return render json: { error: 'missing scheduled_at_local' }, status: 400 unless local.present?

    c.update!(scheduled_at: parse_london_wall_to_utc(local))
    render json: { ok: true }
  end

  def send_now
    c = Campaign.find(params[:id])
    CampaignTriggerJob.perform_later(c.id)
    render json: { enqueued: true }
  end

  def show
    c = Campaign.includes(:emails).find(params[:id])
    render json: c.as_json(include: :emails)
  end

  def destroy
    Campaign.find(params[:id]).destroy!
    render json: { ok: true }
  end

  private

  # "YYYY-MM-DDTHH:MM" (UK wall-time) -> UTC Time
  def parse_london_wall_to_utc(local_s)
    y, m, rest = local_s.split('-')
    d, hm = rest.split('T')
    h, min = hm.split(':')
    Time.use_zone('London') { Time.zone.local(y, m, d, h, min).utc }
  end
end