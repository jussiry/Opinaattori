# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 4) do

  create_table "comments", :force => true do |t|
    t.text     "text"
    t.integer  "opinion_id"
    t.integer  "user_id"
    t.integer  "reply_id"
    t.boolean  "anonymous"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feedbacks", :force => true do |t|
    t.integer  "user_id"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "opinion_statuses", :force => true do |t|
    t.integer  "opinion_id"
    t.integer  "user_id"
    t.integer  "status",         :default => 0
    t.integer  "hidden_counter", :default => 0
    t.boolean  "anonymous"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "opinions", :force => true do |t|
    t.string   "text"
    t.integer  "creator_id"
    t.integer  "pos",            :default => 0
    t.integer  "neg",            :default => 0
    t.integer  "hidden",         :default => 0
    t.boolean  "anonymous"
    t.integer  "comments_count", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pictures", :force => true do |t|
    t.string   "picture_type"
    t.binary   "picture_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "opinion_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "password"
    t.string   "email"
    t.string   "name"
    t.integer  "sex"
    t.date     "birthdate"
    t.string   "url"
    t.string   "current_session_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "small_picture_id"
    t.string   "op_picture_id"
    t.string   "picture_id"
    t.string   "large_picture_id"
  end

end
