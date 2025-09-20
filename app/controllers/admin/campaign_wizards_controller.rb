# frozen_string_literal: true
require "csv"

class Admin::CampaignWizardsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_manager_or_admin!, only: %i[new show upload_csv preview configure finalize cancel]
  before_action :load_temp_upload,          only: %i[preview configure finalize cancel]
  before_action :set_invalids,              only: %i[preview configure finalize]
  before_action :load_mandrill_templates,   only: %i[configure]

  # GET /admin/campaign_wizard (singular resource#show)
  def show
    # just render upload form (view: app/views/admin/campaign_wizards/show.html.erb)
  end

  def new
    redirect_to admin_campaign_wizard_path
  end

  # POST /admin/campaign_wizard/upload_csv
  def upload_csv
    file = params[:file]
    return redirect_back fallback_location: admin_campaign_wizard_path, alert: "Please choose a CSV file." unless file

    rows = CSV.read(file.tempfile, headers: true).map(&:to_h)

    norm = ->(h) { (h || "").to_s.strip }
    headers  = rows.first&.keys&.map { |k| norm.call(k) } || []
    email_key = headers.find { |h| h.casecmp("email").zero? }
    return redirect_back fallback_location: admin_campaign_wizard_path, alert: "CSV must contain an EMAIL column." unless email_key

    upload   = TempUpload.create!(user: current_user, token: SecureRandom.hex(12), filename: file.original_filename)
    invalids = []

    rows.each_with_index do |row, i|
      clean = {}
      row.each { |k, v| clean[norm.call(k)] = norm.call(v) }

      addr = clean[email_key]
      if addr.blank? || !(addr =~ URI::MailTo::EMAIL_REGEXP)
        invalids << { row: i + 2, email: addr.presence || "(blank)" } # +2 because headers line is row 1
        next
      end

      fields = clean.except(email_key)
      TempRecipient.create!(temp_upload: upload, email: addr, fields: fields)
    end

    upload.update!(row_count: upload.temp_recipients.count)

    session[:campaign_wizard] = { token: upload.token, invalids: invalids }
    redirect_to preview_admin_campaign_wizard_path(token: upload.token)
  end

  # GET /admin/campaign_wizard/preview
  def preview
    return unless ensure_temp_upload!
    @recipients = @temp_upload.temp_recipients.order(:id)
    @headers    = derive_headers_from_sample(@recipients)
  end

  # POST /admin/campaign_wizard/configure
  # Renders the form (POST render) so we don’t need a GET route.
  def configure
    # token from query, nested, or the latest upload
    token = params[:token].presence ||
      params.dig(:campaign, :token).presence ||
      @temp_upload&.token

    # keep previously entered values (if any)
    @form = state_for(token).slice(:subject, :preview_text, :template_slug, :scheduled_at_local, :send_now)
    @form[:token] ||= token
  end

  # POST /admin/campaign_wizard/finalize
  def finalize
    # token comes nested in the form
    token = params.dig(:campaign, :token)

    # load via before_action
    # (@temp_upload is set by load_temp_upload and now finds nested tokens)
    recipients = @temp_upload.temp_recipients.order(:id)
    if recipients.empty?
      flash[:alert] = "No valid recipients to send to."
      return redirect_to admin_campaign_wizard_path(token: @temp_upload.token)
    end

    subject      = params.dig(:campaign, :subject).to_s.strip
    preview_text = params.dig(:campaign, :preview_text).to_s.strip
    send_now     = params.dig(:campaign, :send_now) == "1"
    local_time   = params.dig(:campaign, :scheduled_at_local).to_s.strip
    template     = params[:template_slug].to_s.strip  # from select_tag :template_slug

    errors = []
    errors << "Subject is required"    if subject.blank?
    errors << "Template is required"   if template.blank?
    errors << "Choose a schedule time" if !send_now && local_time.blank?

    if errors.any?
      # keep filled values around
      stash_state(token, {
        subject: subject,
        preview_text: preview_text,
        template_slug: template,
        send_now: send_now,
        scheduled_at_local: local_time
      })
      flash[:alert] = errors.join(", ")
      return redirect_to configure_admin_campaign_wizard_path(token: @temp_upload.token)
    end

    scheduled_at_utc =
      if send_now
        Time.current.utc
      elsif local_time.present?
        parse_london_wall_to_utc(local_time)
      end

    # IMPORTANT: only use allowed statuses — no "QUEUED"
    campaign = Campaign.new(
      name:          "CSV import #{Time.current.to_i}",
      template_name: template,
      subject:       subject,
      preview_text:  preview_text,
      scheduled_at:  scheduled_at_utc,
      status:        "SCHEDULED",
      user:          current_user
    )

    recipients.each do |r|
      campaign.emails.build(
        address: r.email,
        custom_fields: r.fields,
        status: "PENDING"
      )
    end

    Campaign.transaction do
      campaign.save!

      if send_now
        # fire immediately
        CampaignTriggerJob.perform_later(campaign.id)
      end

      # cleanup temp data
      @temp_upload.destroy!
      session.delete(:campaign_wizard)
    end

    flash[:notice] = send_now ? "Campaign is sending." : "Campaign scheduled."
    redirect_to admin_campaign_path(campaign)
  rescue => e
    Rails.logger.error("[wizard] finalize failed: #{e.class}: #{e.message}")
    flash[:alert] = "Could not finalize campaign: #{e.message}"
    redirect_to configure_admin_campaign_wizard_path(token: token.presence || @temp_upload&.token)
  end

  # DELETE /admin/campaign_wizard/cancel
  def cancel
    if @temp_upload
      TempRecipient.where(temp_upload_id: @temp_upload.id).delete_all
      @temp_upload.destroy
    end
    session.delete(:campaign_wizard)
    redirect_to admin_campaign_wizard_path, notice: "Upload cancelled and temporary data cleared."
  end

  # --- session helpers ---
  def wizard_state
    session[:campaign_wizard] ||= {}
  end

  def stash_state(token, hash)
    wizard_state[token] ||= {}
    wizard_state[token].merge!(hash.compact)
  end

  def state_for(token)
    wizard_state[token] || {}
  end

  private

  def load_mandrill_templates
    @templates = Rails.cache.fetch("mandrill:templates:list", expires_in: 10.minutes) do
      MandrillClient.new.list_templates
    end
  rescue MandrillClient::Error => e
    Rails.logger.warn("Mandrill templates failed: #{e.message}")
    @templates = []
  end

  # "YYYY-MM-DDTHH:MM" (UK wall-time) -> UTC Time
  def parse_london_wall_to_utc(local_s)
    y, m, rest = local_s.to_s.split('-')
    d, hm = rest.to_s.split('T')
    h, min = (hm || "").split(':')
    Time.use_zone('London') { Time.zone.local(y, m, d, h, min).utc }
  end

  def derive_headers_from_sample(rows)
    sample = rows.first
    return [] unless sample&.fields.is_a?(Hash)
    ["EMAIL"] + sample.fields.keys
  end

  # app/controllers/admin/campaign_wizards_controller.rb

  private

  def load_temp_upload
    token = params[:token].presence ||
      params.dig(:campaign, :token).presence ||
      session.dig(:campaign_wizard, :token)

    @temp_upload = TempUpload.find_by(token: token, user_id: current_user.id)
    if @temp_upload.nil?
      redirect_to new_admin_campaign_wizard_path, alert: "Upload not found or expired." and return
    end
    @recipients = @temp_upload.temp_recipients.order(:id)
  end

  def ensure_temp_upload!
    if @temp_upload.nil?
      redirect_to admin_campaign_wizard_path, alert: "Upload not found or expired."
      return false
    end
    true
  end

  def set_invalids
    @invalids = session.dig(:campaign_wizard, :invalids) || []
  end
end