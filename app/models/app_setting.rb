# app/models/app_setting.rb
class AppSetting < ApplicationRecord
  DEFAULT_TZ = "Europe/London"

  def self.instance
    first_or_create!(timezone: DEFAULT_TZ)
  end
end