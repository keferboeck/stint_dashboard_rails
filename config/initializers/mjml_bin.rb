if defined?(Mjml)
  Mjml.setup do |config|
    if ENV["SECRET_KEY_BASE_DUMMY"] == "1"
      # No-op during build so it doesn’t error
      config.mjml_binary = "true" if config.respond_to?(:mjml_binary=)
      config.raise_render_exception = false if config.respond_to?(:raise_render_exception)
    else
      node_bin = Rails.root.join("node_modules", ".bin", "mjml")
      if File.exist?(node_bin)
        config.mjml_binary = node_bin.to_s if config.respond_to?(:mjml_binary=)
        config.mjml_bin    = node_bin.to_s if config.respond_to?(:mjml_bin=) # older gem versions
      end
    end
  end
end