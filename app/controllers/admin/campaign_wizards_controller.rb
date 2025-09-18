# frozen_string_literal: true
require "csv"

class Admin::CampaignWizardsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_manager_or_admin!, only: %i[new upload_csv preview configure finalize cancel]
  before_action :load_temp_upload,          only: %i[preview configure finalize cancel]
  before_action :set_invalids,              only: %i[preview configure finalize]
  before_action :load_mandrill_templates, only: %i[configure]

  def new

  end

  def show
    # nothing special; renders upload form
  end

  # POST /admin/campaign_wizard/upload_csv
  # - parses CSV
  # - trims whitespace in headers & values
  # - filters invalid emails (must have EMAIL column)
  # - stores valid rows in TempRecipient linked to a TempUpload
  # - shows preview page with a scrollable table + invalid list
  def upload_csv
    file = params[:file]
    return redirect_back fallback_location: new_admin_campaign_wizard_path, alert: "Please choose a CSV file." unless file

    rows = CSV.read(file.tempfile, headers: true).map(&:to_h)

    # normalise headers and values (strip whitespace)
    norm = ->(h) { (h || "").to_s.strip }
    headers = rows.first&.keys&.map { |k| norm.call(k) } || []
    email_key = headers.find { |h| h.casecmp("email").zero? }
    return redirect_back fallback_location: new_admin_campaign_wizard_path, alert: "CSV must contain an EMAIL column." unless email_key

    # build upload & recipients
    upload = TempUpload.create!(user: current_user, token: SecureRandom.hex(12), filename: file.original_filename)
    invalids = []

    rows.each_with_index do |row, i|
      clean = {}
      row.each { |k, v| clean[norm.call(k)] = norm.call(v) }

      addr = clean[email_key]
      if addr.blank? || !(addr =~ URI::MailTo::EMAIL_REGEXP)
        invalids << { row: i + 2, email: addr.presence || "(blank)" } # +2 because headers are row 1
        next
      end

      fields = clean.except(email_key)
      TempRecipient.create!(temp_upload: upload, email: addr, fields: fields)
    end

    upload.update!(row_count: upload.temp_recipients.count)

    # Hand preview everything it needs
    session[:campaign_wizard] = {
      token: upload.token,
      invalids: invalids
    }

    redirect_to preview_admin_campaign_wizard_path(token: upload.token)
  end

  # GET /admin/campaign_wizard/preview
  # (You’ll usually land here from upload_csv; keep it simple.)
  def preview
    @temp_upload = TempUpload.where(user_id: current_user.id).order(id: :desc).first
    unless @temp_upload
      redirect_to admin_campaign_wizard_path, alert: "Nothing to preview — upload a CSV first." and return
    end
    @rows = TempRecipient.where(temp_upload_id: @temp_upload.id).limit(500)
    @headers = derive_headers_from_sample(@rows)
    @invalid = [] # only shown immediately after upload; keep empty here
  end

  # POST /admin/campaign_wizard/configure
  # Renders the form for subject/template/schedule, tied to a temp_upload_id
  def configure
    token = params[:token] || params.dig(:campaign, :token) || @tu&.token
    subject       = params.dig(:campaign, :subject)
    preview_text  = params.dig(:campaign, :preview_text)
    template_name = params.dig(:campaign, :template_name)
    send_now      = params.dig(:campaign, :send_now) == "1"
    scheduled_at  = params.dig(:campaign, :scheduled_at_local)

    # Initial GET-render (no params yet): just show form with any saved state
    unless request.post?
      @form = state_for(token).slice(:subject, :preview_text, :template_name, :scheduled_at_local, :send_now)
      @form[:token] ||= token
      return render :configure
    end

    # Validate
    errors = []
    errors << "Subject is required"                 if subject.blank?
    errors << "Template is required"                if template_name.blank?
    errors << "Choose send now or schedule time"    if !send_now && scheduled_at.blank?

    # Persist form state in session so we don’t lose inputs on error
    stash_state(token, {
      subject: subject,
      preview_text: preview_text,
      template_name: template_name,
      send_now: send_now,
      scheduled_at_local: scheduled_at
    })

    if errors.any?
      @form   = state_for(token)
      @errors = errors
      return render :configure, status: :unprocessable_entity
    end

    # Store in session and move to finalize
    redirect_to finalize_admin_campaign_wizard_path(token: token)
  end

  # POST /admin/campaign_wizard/finalize
  # Creates Campaign + Emails, deletes temp rows.
  def finalize
    token = params[:token] || @tu&.token
    st = state_for(token)

    if st.blank?
      flash[:alert] = "Session expired. Please re-upload your CSV."
      return redirect_to new_admin_campaign_wizard_path
    end

    # Build campaign
    utc_instant =
      if st[:send_now]
        nil
      elsif st[:scheduled_at_local].present?
        parse_london_wall_to_utc(st[:scheduled_at_local])
      end

    c = Campaign.new(
      name:          st[:filename].presence || "Untitled campaign",
      template_name: st[:template_name],
      subject:       st[:subject],
      preview_text:  st[:preview_text],
      scheduled_at:  st[:send_now] ? Time.current.utc : utc_instant,
      status:        st[:send_now] ? "SCHEDULED" : "SCHEDULED"
    )

    TempRecipient.where(temp_upload_id: @tu.id).find_each do |r|
      c.emails.build(address: r.email, custom_fields: r.fields, status: "PENDING")
    end

    if c.save
      # cleanup temp rows
      TempRecipient.where(temp_upload_id: @tu.id).delete_all
      @tu.destroy
      wizard_state.delete(token)

      flash[:notice] = st[:send_now] ? "Campaign queued to send now" : "Campaign scheduled"
      redirect_to admin_campaign_path(c)
    else
      @errors = c.errors.full_messages
      @form   = st
      load_mandrill_templates
      render :configure, status: :unprocessable_entity
    end
  end

  # DELETE /admin/campaign_wizard/cancel
  # Wipes the latest temp upload for this user.
  def cancel
    tu = TempUpload.where(user_id: current_user.id).order(id: :desc).first
    if tu
      TempRecipient.where(temp_upload_id: tu.id).delete_all
      tu.destroy
      redirect_to admin_campaign_wizard_path, notice: "Upload cancelled and temporary data cleared."
    else
      redirect_to admin_campaign_wizard_path, alert: "Nothing to cancel."
    end
  end

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
    @templates = MandrillTemplates.list_names
  end

  # "YYYY-MM-DDTHH:MM" (UK wall-time) -> UTC Time
  def parse_london_wall_to_utc(local_s)
    y, m, rest = local_s.split('-')
    d, hm = rest.split('T')
    h, min = hm.split(':')
    Time.use_zone('London') { Time.zone.local(y, m, d, h, min).utc }
  end

  def derive_headers_from_sample(rows)
    sample = rows.first
    return [] unless sample&.fields.is_a?(Hash)   # ⬅️ was custom_fields
    ["EMAIL"] + sample.fields.keys                # ⬅️ was custom_fields
  end

  def load_temp_upload
    token = params[:token].presence || session.dig(:campaign_wizard, :token)
    @temp_upload = TempUpload.find_by(token: token, user_id: current_user.id)
    if @temp_upload.nil?
      redirect_to new_admin_campaign_wizard_path, alert: "Upload not found or expired." and return
    end
    @recipients = @temp_upload.temp_recipients.order(:id)
  end

  def set_invalids
    @invalids = session.dig(:campaign_wizard, :invalids) || []
  end
end