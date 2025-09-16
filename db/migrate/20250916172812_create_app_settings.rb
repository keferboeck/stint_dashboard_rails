class CreateAppSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :app_settings do |t|
      t.string  :timezone, null: false, default: "Europe/London"
      t.boolean :scheduling_on_hold, null: false, default: false
      t.boolean :cron_enabled,       null: false, default: false
      t.timestamps
    end
  end
end
