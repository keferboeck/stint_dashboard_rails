class AddNotificationPrefsToUsers < ActiveRecord::Migration[8.0]
  def change
    # --- role (skip if it already exists) ---
    add_column :users, :role, :string, null: false, default: "viewer" unless column_exists?(:users, :role)
    add_index  :users, :role unless index_exists?(:users, :role)

    # --- notification preferences (A–F) ---
    add_column :users, :notify_new_scheduled_all,  :boolean, null: false, default: false unless column_exists?(:users, :notify_new_scheduled_all)
    add_column :users, :notify_copy_all,           :boolean, null: false, default: false unless column_exists?(:users, :notify_copy_all)
    add_column :users, :notify_summary_all,        :boolean, null: false, default: false unless column_exists?(:users, :notify_summary_all)

    add_column :users, :notify_new_scheduled_mine, :boolean, null: false, default: false unless column_exists?(:users, :notify_new_scheduled_mine)
    add_column :users, :notify_copy_mine,          :boolean, null: false, default: false unless column_exists?(:users, :notify_copy_mine)
    add_column :users, :notify_summary_mine,       :boolean, null: false, default: false unless column_exists?(:users, :notify_summary_mine)

    # --- per-user preferred time zone (default UK) ---
    add_column :users, :preferred_time_zone, :string, null: false, default: "Europe/London" unless column_exists?(:users, :preferred_time_zone)
  end
end
