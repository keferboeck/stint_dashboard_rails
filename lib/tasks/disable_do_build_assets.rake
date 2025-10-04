# DO App Platform builds run:
#   SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
# We detect that and turn assets + JS + Tailwind steps into no-ops,
# because we've already committed prebuilt assets.
if ENV["SECRET_KEY_BASE_DUMMY"] == "1"
  # Nuke assets:precompile so it doesn't pull in sub-tasks
  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].clear
  end

  namespace :assets do
    desc "No-op precompile on DO build (assets are prebuilt and committed)"
    task :precompile do
      puts "Skipping assets:precompile (DO build detected via SECRET_KEY_BASE_DUMMY=1)"
    end
  end

  # Belt-and-braces: neutralize jsbundling & tailwind tasks if something still calls them
  %w[javascript:install javascript:build tailwindcss:build].each do |t|
    if Rake::Task.task_defined?(t)
      Rake::Task[t].clear
    end
  end

  namespace :javascript do
    task :install { puts "Skipping javascript:install (DO build)" }
    task :build   { puts "Skipping javascript:build (DO build)" }
  end

  namespace :tailwindcss do
    task :build { puts "Skipping tailwindcss:build (DO build)" }
  end
end