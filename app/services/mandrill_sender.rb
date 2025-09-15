class MandrillSender
  def initialize
    @client = MailchimpTransactional::Client.new(ENV.fetch('MANDRILL_API_KEY'))
  end

  # Sends a template to one recipient.
  # We include PREVIEW_TEXT as a global merge var; render it in your Mandrill template preheader.
  def send_template(template_name:, subject:, preview_text:, to_address:, merge_vars: {})
    message = {
      subject: subject || 'Hello from Stint',
      from_email: ENV.fetch('FROM_EMAIL', 'no-reply@stint.co'),
      from_name:  ENV.fetch('FROM_NAME',  'Stint HQ'),
      to: [{ email: to_address, type: 'to' }],
      merge_language: 'mailchimp',
      global_merge_vars: merge_vars.merge('PREVIEW_TEXT' => preview_text.to_s)
                                   .map { |k, v| { name: k, content: v } }
    }
    @client.messages.send_template({ template_name:, template_content: [], message: })
  end
end