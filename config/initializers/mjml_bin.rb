if defined?(Mjml)
  Mjml.setup do |config|
    node_bin = Rails.root.join("node_modules", ".bin", "mjml")
    config.mjml_bin = node_bin.to_s if File.exist?(node_bin)
    # Don't raise exceptions if mjml isn't present at boot
    config.raise_render_exception = false if config.respond_to?(:raise_render_exception)
  end
end