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

ActiveRecord::Schema[8.0].define(version: 2025_02_01_030222) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "character_events", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_character_events_on_character_id"
    t.index ["event_id"], name: "index_character_events_on_event_id"
  end

  create_table "character_locations", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_character_locations_on_character_id"
    t.index ["location_id"], name: "index_character_locations_on_location_id"
  end

  create_table "characters", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "role"
    t.bigint "story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "new", default: true
    t.bigint "location_id"
    t.index ["location_id"], name: "index_characters_on_location_id"
    t.index ["story_id"], name: "index_characters_on_story_id"
  end

  create_table "events", force: :cascade do |t|
    t.text "description"
    t.text "short"
    t.string "category"
    t.bigint "story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "new", default: true
    t.index ["story_id"], name: "index_events_on_story_id"
  end

  create_table "facts", force: :cascade do |t|
    t.text "text"
    t.bigint "story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "new", default: true
    t.index ["story_id"], name: "index_facts_on_story_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "category"
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_items_on_character_id"
  end

  create_table "location_events", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_location_events_on_event_id"
    t.index ["location_id"], name: "index_location_events_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "category"
    t.bigint "story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "new", default: true
    t.index ["story_id"], name: "index_locations_on_story_id"
  end

  create_table "mission_characters", force: :cascade do |t|
    t.string "role"
    t.bigint "mission_id", null: false
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_mission_characters_on_character_id"
    t.index ["mission_id"], name: "index_mission_characters_on_mission_id"
  end

  create_table "mission_events", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "mission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_mission_events_on_event_id"
    t.index ["mission_id"], name: "index_mission_events_on_mission_id"
  end

  create_table "mission_locations", force: :cascade do |t|
    t.string "role"
    t.bigint "mission_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_mission_locations_on_location_id"
    t.index ["mission_id"], name: "index_mission_locations_on_mission_id"
  end

  create_table "missions", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "status"
    t.bigint "story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "new", default: true
    t.index ["story_id"], name: "index_missions_on_story_id"
  end

  create_table "stories", force: :cascade do |t|
    t.string "title"
    t.string "genre"
    t.text "overview"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_stories_on_user_id"
  end

  create_table "summaries", force: :cascade do |t|
    t.text "text"
    t.bigint "story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_summaries_on_story_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "character_events", "characters"
  add_foreign_key "character_events", "events"
  add_foreign_key "character_locations", "characters"
  add_foreign_key "character_locations", "locations"
  add_foreign_key "characters", "locations"
  add_foreign_key "characters", "stories"
  add_foreign_key "events", "stories"
  add_foreign_key "facts", "stories"
  add_foreign_key "items", "characters"
  add_foreign_key "location_events", "events"
  add_foreign_key "location_events", "locations"
  add_foreign_key "locations", "stories"
  add_foreign_key "mission_characters", "characters"
  add_foreign_key "mission_characters", "missions"
  add_foreign_key "mission_events", "events"
  add_foreign_key "mission_events", "missions"
  add_foreign_key "mission_locations", "locations"
  add_foreign_key "mission_locations", "missions"
  add_foreign_key "missions", "stories"
  add_foreign_key "stories", "users"
  add_foreign_key "summaries", "stories"
end
