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

ActiveRecord::Schema[7.2].define(version: 2026_08_19_095334) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", default: "Danh mục chính", null: false
    t.string "broker", default: "VNDirect"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "ai_insights", force: :cascade do |t|
    t.integer "kind", default: 0, null: false
    t.date "period_start"
    t.date "period_end"
    t.text "content"
    t.string "ai_model"
    t.integer "status", default: 0, null: false
    t.jsonb "context", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_ai_insights_on_created_at"
    t.index ["kind"], name: "index_ai_insights_on_kind"
    t.index ["user_id"], name: "index_ai_insights_on_user_id"
  end

  create_table "ai_messages", force: :cascade do |t|
    t.integer "role", default: 0, null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_ai_messages_on_created_at"
    t.index ["user_id"], name: "index_ai_messages_on_user_id"
  end

  create_table "cash_flows", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "kind", default: 0, null: false
    t.decimal "amount", precision: 18, scale: 2, default: "0.0", null: false
    t.date "occurred_on", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_cash_flows_on_account_id"
    t.index ["kind"], name: "index_cash_flows_on_kind"
    t.index ["occurred_on"], name: "index_cash_flows_on_occurred_on"
  end

  create_table "stocks", force: :cascade do |t|
    t.string "symbol", null: false
    t.string "name"
    t.string "exchange", default: "HOSE"
    t.decimal "current_price", precision: 15, scale: 2
    t.datetime "price_updated_at"
    t.string "sector"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["symbol"], name: "index_stocks_on_symbol", unique: true
  end

  create_table "trades", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "stock_id", null: false
    t.integer "side", default: 0, null: false
    t.integer "quantity", default: 0, null: false
    t.decimal "price", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "traded_at", null: false
    t.decimal "fee", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "tax", precision: 15, scale: 2, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.date "settlement_date"
    t.string "strategy_tag"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_trades_on_account_id"
    t.index ["side"], name: "index_trades_on_side"
    t.index ["status"], name: "index_trades_on_status"
    t.index ["stock_id"], name: "index_trades_on_stock_id"
    t.index ["strategy_tag"], name: "index_trades_on_strategy_tag"
    t.index ["traded_at"], name: "index_trades_on_traded_at"
  end

  create_table "trading_holidays", force: :cascade do |t|
    t.date "holiday_on", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["holiday_on"], name: "index_trading_holidays_on_holiday_on", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "preferences", default: {}, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "ai_insights", "users"
  add_foreign_key "ai_messages", "users"
  add_foreign_key "cash_flows", "accounts"
  add_foreign_key "trades", "accounts"
  add_foreign_key "trades", "stocks"
end
