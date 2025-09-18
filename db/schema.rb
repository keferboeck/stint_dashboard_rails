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

ActiveRecord::Schema[8.0].define(version: 2025_09_16_215828) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "app_settings", force: :cascade do |t|
    t.string "timezone", default: "Europe/London", null: false
    t.boolean "scheduling_on_hold", default: false, null: false
    t.boolean "cron_enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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

  create_table "temp_recipients", force: :cascade do |t|
    t.bigint "temp_upload_id", null: false
    t.string "email", null: false
    t.jsonb "fields", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["temp_upload_id", "email"], name: "index_temp_recipients_on_temp_upload_id_and_email"
    t.index ["temp_upload_id"], name: "index_temp_recipients_on_temp_upload_id"
  end

  create_table "temp_uploads", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.string "filename"
    t.integer "row_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_temp_uploads_on_token", unique: true
    t.index ["user_id"], name: "index_temp_uploads_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.boolean "notify_new_scheduled_all", default: false, null: false
    t.boolean "notify_copy_all", default: false, null: false
    t.boolean "notify_summary_all", default: false, null: false
    t.boolean "notify_new_scheduled_mine", default: false, null: false
    t.boolean "notify_copy_mine", default: false, null: false
    t.boolean "notify_summary_mine", default: false, null: false
    t.string "preferred_time_zone", default: "Europe/London", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "emails", "campaigns"
  add_foreign_key "temp_recipients", "temp_uploads"
  add_foreign_key "temp_uploads", "users"
end
