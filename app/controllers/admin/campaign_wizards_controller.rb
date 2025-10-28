# frozen_string_literal: true
require "csv"

class Admin::CampaignWizardsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_manager_or_admin!, only: %i[new show upload_csv preview configure finalize cancel]
  before_action :load_temp_upload,          only: %i[preview configure finalize cancel]
  before_action :set_invalids,              only: %i[preview configure finalize]
  before_action :load_mandrill_templates,   only: %i[configure]

  # Allow a simple GET probe that bypasses auth & CSRF (debug only)
  skip_before_action :authenticate_user!, only: :ping
  skip_forgery_protection only: :ping

  def ping
    Rails.logger.info "[wizard] PING reached"
    render plain: "OK", status: :ok
  end

  def auth_ping
    Rails.logger.info "[wizard] AUTH_PING by #{current_user&.email || 'nil'}"
    render plain: "OK (auth)", status: :ok
  end

  # GET /admin/campaign_wizard (singular resource#show)
  def show
    # just render upload form (view: app/views/admin/campaign_wizards/show.html.erb)
  end

  def new
    redirect_to admin_campaign_wizard_path
  end

  # POST /admin/campaign_wizard/upload_csv
  # POST /admin/campaign_wizard/upload_csv
  # POST /admin/campaign_wizard/upload_csv
  def upload_csv
    started_at = Time.current
    Rails.logger.info "[wizard] upload_csv START by #{current_user.email} at #{started_at} (params keys: #{params.keys.inspect})"

    file = params[:file]
    unless file
      Rails.logger.info "[wizard] upload_csv NO FILE"
      return redirect_back fallback_location: admin_campaign_wizard_path, alert: "Please choose a CSV file."
    end

    # get a stable path for CSV
    path = file.respond_to?(:tempfile) ? file.tempfile.path : file.path
    unless path && File.exist?(path)
      Rails.logger.info "[wizard] upload_csv BAD PATH"
      return redirect_back fallback_location: admin_campaign_wizard_path, alert: "Could not read uploaded file."
    end

    # create upload record first
    upload = TempUpload.create!(
      user: current_user,
      token: SecureRandom.hex(12),
      filename: file.original_filename
    )
    Rails.logger.info "[wizard] upload_csv TEMP UPLOAD id=#{upload.id} token=#{upload.token}"

    invalids   = []
    batch      = []
    total_rows = 0
    inserted   = 0
    batch_size = 1_000

    # dev safety cap (so you never block your dev server on a gigantic CSV)
    dev_cap = (Rails.env.development? ? (ENV["WIZARD_MAX_ROWS"] || "10000").to_i : nil)

    norm = ->(h) { (h || "").to_s.strip }

    # --- discover headers (BOM + UTF-8 safe) ---
    headers = nil
    email_key = nil

    CSV.open(path, "r:bom|utf-8", headers: true) do |csv|
      if (first = csv.first)
        headers = first.headers.map { |k| norm.call(k) }
        email_key = headers.find { |h| h.casecmp("email").zero? }
      end
    end

    unless email_key
      upload.destroy
      Rails.logger.info "[wizard] upload_csv NO EMAIL HEADER"
      return redirect_back fallback_location: admin_campaign_wizard_path, alert: "CSV must contain an EMAIL column."
    end
    Rails.logger.info "[wizard] upload_csv EMAIL HEADER OK (#{email_key})"

    # --- parse rows streaming ---
    CSV.foreach(path, headers: true, encoding: "bom|utf-8") do |row|
      total_rows += 1
      clean = {}
      row.to_h.each { |k, v| clean[norm.call(k)] = norm.call(v) }

      addr = clean[email_key]
      if addr.blank? || !(addr =~ URI::MailTo::EMAIL_REGEXP)
        invalids << { row: total_rows + 1, email: addr.presence || "(blank)" }
        next
      end

      fields = clean.except(email_key)
      batch << {
        temp_upload_id: upload.id,
        email: addr,
        fields: fields,
        created_at: Time.current,
        updated_at: Time.current
      }

      if batch.size >= batch_size
        TempRecipient.insert_all(batch)
        inserted += batch.size
        batch.clear
      end

      # dev cap guard (prevents request from becoming “forever” on huge CSVs)
      if dev_cap && (inserted + batch.size) >= dev_cap
        Rails.logger.info "[wizard] upload_csv DEV CAP HIT at #{dev_cap} rows"
        break
      end
    end

    TempRecipient.insert_all(batch) if batch.any?
    inserted += batch.size
    upload.update!(row_count: upload.temp_recipients.count)

    session[:campaign_wizard] = { token: upload.token, invalids: invalids }

    valid_count   = upload.row_count
    invalid_count = invalids.size
    flash[:notice] =
      "Imported #{valid_count} valid #{'email'.pluralize(valid_count)}. " \
        "Skipped #{invalid_count} invalid."

    redirect_to preview_admin_campaign_wizard_path(token: upload.token)
  rescue => e
    Rails.logger.error "[wizard] upload_csv ERROR #{e.class}: #{e.message}\n#{e.backtrace&.first(6)&.join("\n")}"
    redirect_back fallback_location: admin_campaign_wizard_path, alert: "Upload failed: #{e.message}"
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
  # POST /admin/campaign_wizard/finalize
  def finalize
    token = params.dig(:campaign, :token)

    recipients = @temp_upload.temp_recipients.order(:id)
    if recipients.empty?
      flash[:alert] = "No valid recipients to send to."
      return redirect_to admin_campaign_wizard_path(token: @temp_upload.token)
    end

    subject      = params.dig(:campaign, :subject).to_s.strip
    preview_text = params.dig(:campaign, :preview_text).to_s.strip
    send_now     = params.dig(:campaign, :send_now) == "1"
    local_time   = params.dig(:campaign, :scheduled_at_local).to_s.strip
    template     = params[:template_slug].to_s.strip

    errors = []
    errors << "Subject is required"    if subject.blank?
    errors << "Template is required"   if template.blank?
    errors << "Choose a schedule time" if !send_now && local_time.blank?

    if errors.any?
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
      @temp_upload.destroy!
      session.delete(:campaign_wizard)
    end

    # enqueue AFTER commit, and use the job you actually have
    CronTickJob.perform_later(campaign.id) if send_now

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