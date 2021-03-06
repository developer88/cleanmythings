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

ActiveRecord::Schema.define(version: 20141027141144) do

  create_table "slots", force: true do |t|
    t.integer  "user_id"
    t.float    "hours"
    t.boolean  "supplies_by_owner", default: false
    t.integer  "bedrooms",          default: 0
    t.integer  "bathrooms",         default: 1
    t.integer  "how_often",         default: 0
    t.datetime "end_at"
    t.datetime "start_at"
    t.boolean  "cats",              default: false
    t.boolean  "dogs",              default: false
    t.boolean  "pets",              default: false
    t.string   "pets_describe"
    t.integer  "cleaning",          default: 0
    t.string   "priority"
    t.integer  "team",              default: 1
  end

  create_table "users", force: true do |t|
    t.string "name"
    t.string "email"
    t.string "address"
    t.string "zip"
    t.string "phone"
  end

end
