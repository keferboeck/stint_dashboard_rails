# DO App Platform runs: SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
# Detect that and skip asset compilation because we commit prebuilt assets.
if ENV["SECRET_KEY_BASE_DUMMY"] == "1"
  # Clear the real task if it exists
  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].clear
  end

  namespace :assets do
    desc "No-op precompile on DO build (assets are prebuilt and committed)"
    task :precompile do
      puts "Skipping assets:precompile (DO build with SECRET_KEY_BASE_DUMMY=1)"
    end
  end

  # Neutralize jsbundling/tailwind tasks (if they exist) and replace with no-ops
  %w[javascript:install javascript:build tailwindcss:build].each do |t|
    Rake::Task[t].clear if Rake::Task.task_defined?(t)
  end

  namespace :javascript do
    desc "No-op javascript:install"
    task :install do
      puts "Skipping javascript:install (DO build)"
    end

    desc "No-op javascript:build"
    task :build do
      puts "Skipping javascript:build (DO build)"
    end
  end

  namespace :tailwindcss do
    desc "No-op tailwindcss:build"
    task :build do
      puts "Skipping tailwindcss:build (DO build)"
    end
  end
end