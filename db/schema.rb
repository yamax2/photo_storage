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

ActiveRecord::Schema[7.0].define(version: 2022_10_16_045347) do
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
    t.datetime "original_timestamp", precision: nil
    t.bigint "size", default: 0, null: false
    t.string "content_type", limit: 30, null: false
    t.integer "width", default: 0, null: false
    t.integer "height", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "md5", limit: 32, null: false
    t.string "sha256", limit: 64, null: false
    t.bigint "views", default: 0, null: false
    t.string "tz", limit: 50, default: "Asia/Yekaterinburg", null: false
    t.jsonb "props", default: {}, null: false
    t.integer "folder_index", default: 0, null: false
    t.index ["md5", "sha256"], name: "uq_photos", unique: true
    t.index ["rubric_id"], name: "index_photos_on_rubric_id"
    t.index ["yandex_token_id"], name: "index_photos_on_yandex_token_id", where: "(yandex_token_id IS NOT NULL)"
  end

  create_table "rubrics", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.text "description"
    t.bigint "rubric_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "rubrics_count", default: 0, null: false
    t.bigint "photos_count", default: 0, null: false
    t.bigint "main_photo_id"
    t.integer "ord"
    t.bigint "tracks_count", default: 0, null: false
    t.boolean "desc_order", default: false, null: false
    t.boolean "hide_common_stat", default: false, null: false
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
    t.decimal "duration", default: "0.0", null: false
    t.decimal "distance", default: "0.0", null: false
    t.datetime "started_at", precision: nil
    t.point "bounds", default: [], null: false, array: true
    t.text "color", default: "red", null: false
    t.text "external_info"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "finished_at", precision: nil
    t.integer "folder_index", default: 0, null: false
    t.index ["md5", "sha256"], name: "uq_tracks", unique: true
    t.index ["rubric_id"], name: "index_tracks_on_rubric_id"
    t.index ["yandex_token_id"], name: "index_tracks_on_yandex_token_id", where: "(yandex_token_id IS NOT NULL)"
  end

  create_table "yandex_tokens", force: :cascade do |t|
    t.string "user_id", limit: 20, null: false
    t.string "login", limit: 255, null: false
    t.string "access_token", limit: 100, null: false
    t.datetime "valid_till", precision: nil, null: false
    t.string "refresh_token", limit: 100, null: false
    t.string "dir", limit: 255
    t.string "other_dir", limit: 255
    t.boolean "active", default: false, null: false
    t.bigint "used_space", default: 0, null: false
    t.bigint "total_space", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "last_archived_at", precision: nil
    t.jsonb "folder_indexes", default: {"other_folder_index"=>0, "photos_folder_index"=>0, "other_folder_archive_from"=>0, "photos_folder_archive_from"=>0}, null: false
    t.index ["user_id"], name: "index_yandex_tokens_on_user_id", unique: true
  end

  add_foreign_key "photos", "rubrics", name: "fk_photo_rubrics", on_update: :cascade, on_delete: :restrict
  add_foreign_key "photos", "yandex_tokens", name: "fk_photo_tokens", on_update: :cascade, on_delete: :restrict
  add_foreign_key "rubrics", "photos", column: "main_photo_id", name: "fk_rubrics_main_photo", on_update: :cascade, on_delete: :nullify
  add_foreign_key "rubrics", "rubrics", name: "fk_rubrics", on_update: :cascade, on_delete: :restrict
  add_foreign_key "tracks", "rubrics", name: "fk_track_rubrics", on_update: :cascade, on_delete: :restrict
  add_foreign_key "tracks", "yandex_tokens", name: "fk_tracks_tokens", on_update: :cascade, on_delete: :restrict
end
