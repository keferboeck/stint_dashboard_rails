# Skip the whole assets:precompile when ASSETS_PRECOMPILE_NOOP=1
if ENV["ASSETS_PRECOMPILE_NOOP"] == "1"
  Rake::Task["assets:precompile"].clear if Rake::Task.task_defined?("assets:precompile")
  namespace :assets do
    desc "No-op precompile (assets are prebuilt and committed)"
    task :precompile do
      puts "Skipping assets:precompile (prebuilt)"
    end
  end
end