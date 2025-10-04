# lib/tasks/disable_do_build_assets.rake
# DO App Platform builds run:
#   SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
# Detect that and skip assets/js/tailwind because assets are prebuilt and committed.
if ENV["SECRET_KEY_BASE_DUMMY"] == "1"
  # Skip the whole precompile
  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].clear
  end

  namespace :assets do
    desc "No-op precompile on DO build (assets are prebuilt and committed)"
    task :precompile do
      puts "Skipping assets:precompile (DO build detected via SECRET_KEY_BASE_DUMMY=1)"
    end
  end

  # Belt-and-braces: neutralize jsbundling & tailwind tasks
  %w[javascript:install javascript:build tailwindcss:build].each do |t|
    Rake::Task[t].clear if Rake::Task.task_defined?(t)
  end

  namespace :javascript do
    task :install do
      puts "Skipping javascript:install (DO build)"
    end

    task :build do
      puts "Skipping javascript:build (DO build)"
    end
  end

  namespace :tailwindcss do
    task :build do
      puts "Skipping tailwindcss:build (DO build)"
    end
  end
end