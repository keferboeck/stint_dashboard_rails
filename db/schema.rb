# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_15_190152) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.string "name"
    t.string "template_name"
    t.string "subject"
    t.string "preview_text"
    t.datetime "scheduled_at"
    t.string "status"
    t.text "failure_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_campaigns_on_status"
  end

  create_table "emails", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.string "address"
    t.jsonb "custom_fields"
    t.datetime "sent_at"
    t.string "status"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_emails_on_address"
    t.index ["campaign_id"], name: "index_emails_on_campaign_id"
    t.index ["status"], name: "index_emails_on_status"
  end

  add_foreign_key "emails", "campaigns"
end
