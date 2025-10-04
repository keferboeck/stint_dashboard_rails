# lib/tasks/disable_do_build_assets.rake
if ENV["SECRET_KEY_BASE_DUMMY"] == "1"
  %w[javascript:install javascript:build].each do |t|
    Rake::Task[t].clear if Rake::Task.task_defined?(t)
  end
end