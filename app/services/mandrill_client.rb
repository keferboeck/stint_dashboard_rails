# app/services/mandrill_client.rb
require "net/http"
require "json"
require "uri"

class MandrillClient
  class Error < StandardError; end

  BASE = "https://mandrillapp.com/api/1.0"

  def initialize(api_key: ENV["MANDRILL_API_KEY"])
    raise Error, "Missing MANDRILL_API_KEY" if api_key.blank?
    @api_key = api_key
  end

  def list_templates
    post_json("/templates/list.json", { key: @api_key })
      .map { |t|
        {
          name:       t["name"],
          slug:       t["slug"].presence || t["name"],
          updated_at: t["updated_at"],
          labels:     t["labels"] || []
        }
      }
  rescue => e
    raise Error, "Mandrill error: #{e.message}"
  end

  def send_template(template_slug:, subject:, to:, merge_vars:, from_email:, from_name:, headers: {}, tags: [])
    message = {
      subject:     subject,
      from_email:  from_email,
      from_name:   from_name,
      to:          to,
      merge_vars:  merge_vars,
      headers:     headers,
      tags:        tags,
      auto_text:   true,
      important:   false
    }
    post_json("/messages/send-template.json", {
      key:             @api_key,
      template_name:   template_slug,
      template_content: [],   # not used when we rely on stored template
      message:         message
    })
  end

  private

  def post_json(path, payload)
    path = path.sub(%r{^/}, "")                  # <-- strip leading slash
    uri  = URI.join("#{BASE}/", path)            # <-- keep /api/1.0
    req  = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json" })
    req.body = JSON.dump(payload)

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    raise Error, "HTTP #{res.code} #{res.message}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  end
end