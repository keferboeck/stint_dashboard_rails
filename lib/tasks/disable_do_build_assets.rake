# Rakefile (replace the whole file with this)
if ENV["SECRET_KEY_BASE_DUMMY"] == "1"
  # Define a noop precompile task *before* loading the app,
  # so Rails/ActiveRecord never boot during DO's image build.
  task "assets:precompile" do
    puts "Skipping assets:precompile (DO build with SECRET_KEY_BASE_DUMMY=1)"
  end
else
  require_relative "config/application"
  Rails.application.load_tasks
end