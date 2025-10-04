# Use mjml-rails if present, but never crash the app if MJML is missing.
if defined?(Mjml)
  Mjml.setup do |config|
    # Prefer explicit binary via ENV, otherwise try local node_modules
    if ENV["MJML_BINARY"].present?
      config.mjml_binary = ENV["MJML_BINARY"]
    else
      node_bin = Rails.root.join("node_modules", ".bin", "mjml")
      config.mjml_binary = node_bin.to_s if File.exist?(node_bin)
    end

    # Important: don't raise on missing binary; log & continue
    if config.respond_to?(:raise_render_exception)
      config.raise_render_exception = false
    end
  end
end