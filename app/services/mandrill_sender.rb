# app/services/mandrill_sender.rb
class MandrillSender
  def initialize
    @client     = MandrillClient.new
    @from_email = ENV.fetch("MANDRILL_FROM_EMAIL")
    @from_name  = ENV.fetch("MANDRILL_FROM_NAME", "Stint")
  end

  # Sends all PENDING emails for the campaign via a Mandrill template (slug in campaign.template_name)
  # Marks each Email row SENT/FAILED accordingly. Raises if the API errors.
  def send_campaign!(campaign)
    template_slug = campaign.template_name
    subject       = campaign.subject.to_s
    raise "Missing template slug" if template_slug.blank?
    raise "Missing subject"       if subject.blank?

    to = []
    merge_vars = []

    campaign.emails.where(status: "PENDING").find_each do |e|
      to << { email: e.address, type: "to" }
      # Mandrill wants merge_vars per-recipient:
      vars = e.custom_fields.to_h.map { |k, v| { name: k.to_s, content: v } }
      merge_vars << { rcpt: e.address, vars: vars }
    end

    return 0 if to.empty?

    # Fire off one send-template call (Mandrill can batch)
    res = @client.send_template(
      template_slug: template_slug,
      subject: subject,
      to: to,
      merge_vars: merge_vars,
      from_email: @from_email,
      from_name:  @from_name,
      headers:    { "X-Campaign-ID" => campaign.id.to_s },
      tags:       ["stint-dashboard", "campaign-#{campaign.id}"]
    )

    # Update rows from API result (array with status per rcpt)
    sent_count = 0
    Array(res).each do |item|
      rcpt   = item["email"] || item[:email]
      status = (item["status"] || item[:status]).to_s.upcase # "sent", "rejected", "invalid"
      email  = campaign.emails.find_by(address: rcpt)
      next unless email

      case status
      when "SENT"
        email.update_columns(status: "SENT")
        sent_count += 1
      else
        email.update_columns(status: "FAILED")
      end
    end

    sent_count
  end
end