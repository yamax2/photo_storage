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

ActiveRecord::Schema.define(version: 2019_06_09_073940) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

end
