# Ignore ActiveAdmin resource files so Zeitwerk doesn't expect matching constants
Rails.autoloaders.main.ignore(Rails.root.join("app/admin"))