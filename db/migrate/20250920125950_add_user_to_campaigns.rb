# db/migrate/20250920125950_add_user_to_campaigns.rb
class AddUserToCampaigns < ActiveRecord::Migration[8.0]
  def change
    add_reference :campaigns, :user, null: true, foreign_key: true, index: true
  end
end