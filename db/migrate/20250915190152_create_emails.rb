class CreateEmails < ActiveRecord::Migration[8.0]
  def change
    create_table :emails do |t|
      t.references :campaign, null: false, foreign_key: true
      t.string :address
      t.jsonb :custom_fields
      t.datetime :sent_at
      t.string :status
      t.text :error_message

      t.timestamps
    end
    add_index :emails, :address
    add_index :emails, :status
  end
end
