class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns do |t|
      t.string :name
      t.string :template_name
      t.string :subject
      t.string :preview_text
      t.datetime :scheduled_at
      t.string :status
      t.text :failure_reason

      t.timestamps
    end
    add_index :campaigns, :status
  end
end
