# If Rails still calls jsbundling/tailwind tasks, turn them into no-ops
if ENV["ASSETS_PRECOMPILE_NOOP"] == "1"
  %w[javascript:install javascript:build tailwindcss:build].each do |t|
    if Rake::Task.task_defined?(t)
      Rake::Task[t].clear
    end
  end

  namespace :javascript do
    task :install do
      puts "Skipping javascript:install (prebuilt)"
    end
    task :build do
      puts "Skipping javascript:build (prebuilt)"
    end
  end

  namespace :tailwindcss do
    task :build do
      puts "Skipping tailwindcss:build (prebuilt)"
    end
  end
end