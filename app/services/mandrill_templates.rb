# app/services/mandrill_templates.rb
class MandrillTemplates
  def self.list_names
    key = ENV["MANDRILL_API_KEY"]
    return [] if key.blank?

    # The mandrill-api gem exposes Mandrill::API
    # Gemfile should have: gem "mandrill-api"
    api = Mandrill::API.new(key)
    # Returns array of hashes with keys like 'name'
    api.templates.list.map { |t| t["name"] }.uniq.sort
  rescue => e
    Rails.logger.warn("[mandrill] templates.list failed: #{e.class}: #{e.message}")
    []
  end
end