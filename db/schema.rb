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

ActiveRecord::Schema.define(version: 20131125233645) do

  create_table "account_types", force: true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts", force: true do |t|
    t.integer  "user_id",                                                                                           null: false
    t.string   "name",                                        limit: 50,                                            null: false
    t.integer  "bank_id",                                     limit: 255
    t.text     "account_type"
    t.string   "linked_account_number",                       limit: 50
    t.string   "linked_bank_code"
    t.string   "linked_user_id",                              limit: 50
    t.string   "linked_password",                             limit: 50
    t.datetime "linked_last_success_date"
    t.decimal  "linked_last_balance",                                      precision: 10, scale: 2
    t.datetime "linked_last_balance_date"
    t.boolean  "linked_last_attempt_error",                                                         default: false, null: false
    t.string   "linked_last_error_message"
    t.string   "linked_initial_balance_bank_transaction_ids", limit: 1000
    t.integer  "active",                                                                            default: 1,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "initial_transaction_id", limit: 5000,
    t.string   "linked_security_answers"
    t.string   "linked_last_error_message_detailed"
    t.boolean  "linked_last_attempt_error_bad_request"
  end

  create_table "allocation_methods", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "income_frequency_id"
    t.decimal  "monthly_occurance",   precision: 6, scale: 5
    t.boolean  "is_default"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "allocation_plan_items", force: true do |t|
    t.integer  "allocation_plan_id",                          null: false
    t.integer  "envelope_id",                                 null: false
    t.decimal  "amount",             precision: 10, scale: 2, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "allocation_plans", force: true do |t|
    t.integer  "user_id",                                               null: false
    t.string   "name",              limit: 50,                          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "income_id"
    t.decimal  "amount",                       precision: 10, scale: 2
    t.decimal  "monthly_occurance",            precision: 5,  scale: 3
    t.integer  "sort_index"
  end

  create_table "allocations", force: true do |t|
    t.integer  "user_id"
    t.datetime "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  create_table "auto_import_methods", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "banks", force: true do |t|
    t.string   "name",                  limit: 50,   default: "0"
    t.string   "ofx_fid",               limit: 50,   default: "0"
    t.string   "ofx_org",               limit: 50,   default: "0"
    t.string   "ofx_uri",               limit: 500,  default: "0"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "import_id"
    t.boolean  "active"
    t.integer  "auto_import_method_id",              default: 1
    t.string   "notes",                 limit: 1000
    t.boolean  "featured",                           default: false, null: false
  end

  create_table "budgets", force: true do |t|
    t.integer  "user_id"
    t.integer  "envelope_id"
    t.decimal  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "envelope_groups", force: true do |t|
    t.integer  "user_id"
    t.string   "name",       limit: 50,                null: false
    t.integer  "sort_index"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible",               default: true
  end

  create_table "envelopes", force: true do |t|
    t.integer  "user_id",                      null: false
    t.integer  "envelope_group_id",            null: false
    t.string   "name",              limit: 50, null: false
    t.integer  "sort_index"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "income_frequencies", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "monthly_occurance", precision: 6, scale: 5
  end

  create_table "incomes", force: true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.decimal  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "income_frequency_id"
    t.integer  "allocation_method_id"
    t.integer  "allocation_method_grouped_with_income_id"
  end

  create_table "subscription_notifications", force: true do |t|
    t.text     "params"
    t.string   "transaction_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "transaction_type"
  end

  create_table "transaction_filters", force: true do |t|
    t.integer  "user_id",                                          null: false
    t.string   "search_text", limit: 200,                          null: false
    t.decimal  "amount",                  precision: 10, scale: 2
    t.integer  "envelope_id",                                      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: true do |t|
    t.integer  "account_id"
    t.integer  "user_id",                                                    null: false
    t.integer  "envelope_id"
    t.string   "name",                  limit: 200,                          null: false
    t.decimal  "amount",                            precision: 10, scale: 2, null: false
    t.datetime "date",                                                       null: false
    t.string   "notes",                 limit: 250
    t.integer  "parent_transaction_id"
    t.string   "import_id",             limit: 100
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "allocation_id"
    t.integer  "transfer_id"
    t.string   "transaction_type"
  end

  add_index "transactions", ["account_id", "import_id"], name: "index_account_id_and_import_id", unique: true
  add_index "transactions", ["account_id", "user_id"], name: "transactions_idx_user_account"
  add_index "transactions", ["user_id", "envelope_id"], name: "transactions_idx_user_envelope"

  create_table "transfers", force: true do |t|
    t.integer  "user_id"
    t.decimal  "amount",           precision: 10, scale: 2
    t.integer  "from_envelope_id"
    t.integer  "to_envelope_id"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "date"
  end

  create_table "users", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                        default: "",    null: false
    t.integer  "sign_in_count",                default: 0
    t.datetime "last_sign_in_at"
    t.string   "password_digest"
    t.integer  "new_transaction_count_notify"
    t.string   "time_zone"
    t.boolean  "is_subscriber",                default: false
    t.string   "name"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.boolean  "is_trial_period_used",         default: false
  end

  add_index "users", ["email"], name: "users_index_users_on_email"

end
