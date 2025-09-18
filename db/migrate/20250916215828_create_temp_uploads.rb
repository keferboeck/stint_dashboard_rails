class CreateTempUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :temp_uploads do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :token, null: false
      t.string  :filename
      t.integer :row_count, default: 0, null: false
      t.timestamps
    end
    add_index :temp_uploads, :token, unique: true

    create_table :temp_recipients do |t|
      t.references :temp_upload, null: false, foreign_key: true
      t.string :email, null: false
      t.jsonb  :fields, null: false, default: {}
      t.timestamps
    end
    add_index :temp_recipients, [:temp_upload_id, :email]
  end
end
