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

ActiveRecord::Schema[7.1].define(version: 2019_07_20_144941) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "game_types", id: :serial, force: :cascade do |t|
    t.text "slack_team_id", null: false
    t.text "game_name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "games", id: :serial, force: :cascade do |t|
    t.text "logged_by_slack_user_id", null: false
    t.integer "player_one_id", null: false
    t.integer "player_two_id", null: false
    t.float "result", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "slack_team_id", null: false
    t.text "player_one_slack_user_id", null: false
    t.text "player_two_slack_user_id", null: false
    t.integer "game_type_id", null: false
    t.integer "team_size", default: 1, null: false
  end

  create_table "players", id: :serial, force: :cascade do |t|
    t.text "slack_team_id", null: false
    t.text "slack_user_id", null: false
    t.integer "rating", default: 1000, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "game_type_id", null: false
    t.integer "team_size", default: 1, null: false
  end

  add_foreign_key "games", "game_types", on_delete: :cascade
  add_foreign_key "games", "players", column: "player_one_id", on_delete: :cascade
  add_foreign_key "games", "players", column: "player_two_id", on_delete: :cascade
  add_foreign_key "players", "game_types", on_delete: :cascade
end
