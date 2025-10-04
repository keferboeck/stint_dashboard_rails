# Make Devise use the main application layout, but only after Devise is loaded.
Rails.application.config.to_prepare do
  if defined?(Devise) && defined?(DeviseController)
    DeviseController.layout "application"
  end
end