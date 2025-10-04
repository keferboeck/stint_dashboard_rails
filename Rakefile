# Rakefile
if ENV["SECRET_KEY_BASE_DUMMY"] == "1"
  task "assets:precompile" do
    puts "Skipping assets:precompile (DO build with SECRET_KEY_BASE_DUMMY=1)"
  end
else
  require_relative "config/application"
  Rails.application.load_tasks
end