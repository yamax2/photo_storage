# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_01_194514) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "photos", force: :cascade do |t|
    t.string "name", limit: 512, null: false
    t.text "description"
    t.bigint "rubric_id", null: false
    t.bigint "yandex_token_id"
    t.text "storage_filename"
    t.text "local_filename"
    t.jsonb "exif"
    t.point "lat_long"
    t.string "original_filename", limit: 512, null: false
    t.datetime "original_timestamp"
    t.bigint "size", default: 0, null: false
    t.string "content_type", limit: 30, null: false
    t.integer "width", default: 0, null: false
    t.integer "height", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "md5", limit: 32, null: false
    t.string "sha256", limit: 64, null: false
    t.bigint "views", default: 0, null: false
    t.string "tz", limit: 50, default: "Asia/Yekaterinburg", null: false
    t.text "external_info"
    t.index ["md5", "sha256"], name: "uq_photos", unique: true
    t.index ["rubric_id"], name: "index_photos_on_rubric_id"
    t.index ["yandex_token_id"], name: "index_photos_on_yandex_token_id", where: "(yandex_token_id IS NOT NULL)"
  end

  create_table "rubrics", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.text "description"
    t.bigint "rubric_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "rubrics_count", default: 0, null: false
    t.bigint "photos_count", default: 0, null: false
    t.bigint "main_photo_id"
    t.integer "ord"
    t.text "external_info"
    t.index ["main_photo_id"], name: "index_rubrics_on_main_photo_id", where: "(main_photo_id IS NOT NULL)"
    t.index ["rubric_id"], name: "index_rubrics_on_rubric_id"
  end

  create_table "tracks", force: :cascade do |t|
    t.string "name", limit: 512, null: false
    t.bigint "rubric_id", null: false
    t.bigint "yandex_token_id"
    t.text "storage_filename"
    t.text "local_filename"
    t.string "md5", limit: 32, null: false
    t.string "sha256", limit: 64, null: false
    t.string "original_filename", limit: 512, null: false
    t.bigint "size", default: 0, null: false
    t.decimal "avg_speed", default: "0.0", null: false
    t.decimal "duration", default: "0.0", null: false
    t.decimal "distance", default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["md5", "sha256"], name: "uq_tracks", unique: true
    t.index ["rubric_id"], name: "index_tracks_on_rubric_id"
    t.index ["yandex_token_id"], name: "index_tracks_on_yandex_token_id", where: "(yandex_token_id IS NOT NULL)"
  end

  create_table "yandex_tokens", force: :cascade do |t|
    t.string "user_id", limit: 20, null: false
    t.string "login", limit: 255, null: false
    t.string "access_token", limit: 100, null: false
    t.datetime "valid_till", null: false
    t.string "refresh_token", limit: 100, null: false
    t.string "token_type", limit: 20, null: false
    t.string "dir", limit: 255
    t.string "other_dir", limit: 255
    t.boolean "active", default: false
    t.bigint "used_space", default: 0, null: false
    t.bigint "total_space", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_yandex_tokens_on_user_id", unique: true
  end

  add_foreign_key "photos", "rubrics", name: "fk_photo_rubrics", on_update: :cascade, on_delete: :restrict
  add_foreign_key "photos", "yandex_tokens", name: "fk_photo_tokens", on_update: :cascade, on_delete: :restrict
  add_foreign_key "rubrics", "photos", column: "main_photo_id", name: "fk_rubrics_main_photo", on_update: :cascade, on_delete: :nullify
  add_foreign_key "rubrics", "rubrics", name: "fk_rubrics", on_update: :cascade, on_delete: :restrict
end
