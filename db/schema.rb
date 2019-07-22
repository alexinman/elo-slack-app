# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20190720144941) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "game_types", force: :cascade do |t|
    t.text     "slack_team_id", null: false
    t.text     "game_name",     null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "games", force: :cascade do |t|
    t.text     "logged_by_slack_user_id",              null: false
    t.integer  "player_one_id",                        null: false
    t.integer  "player_two_id",                        null: false
    t.float    "result",                               null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.text     "slack_team_id",                        null: false
    t.text     "player_one_slack_user_id",             null: false
    t.text     "player_two_slack_user_id",             null: false
    t.integer  "game_type_id",                         null: false
    t.integer  "team_size",                default: 1, null: false
  end

  create_table "players", force: :cascade do |t|
    t.text     "slack_team_id",                null: false
    t.text     "slack_user_id",                null: false
    t.integer  "rating",        default: 1000, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "game_type_id",                 null: false
    t.integer  "team_size",     default: 1,    null: false
  end

  add_foreign_key "games", "game_types", on_delete: :cascade
  add_foreign_key "games", "players", column: "player_one_id", on_delete: :cascade
  add_foreign_key "games", "players", column: "player_two_id", on_delete: :cascade
  add_foreign_key "players", "game_types", on_delete: :cascade
end
