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

ActiveRecord::Schema[7.0].define(version: 2023_08_25_224132) do
  create_table "accounts", force: :cascade do |t|
    t.string "title"
    t.string "number"
    t.integer "currency_id"
    t.boolean "is_fifo", default: true
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_accounts_on_currency_id"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "currencies", force: :cascade do |t|
    t.string "name"
    t.string "symbol"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_currencies_on_user_id"
  end

  create_table "gain_losses", force: :cascade do |t|
    t.integer "account_id", null: false
    t.date "date"
    t.integer "trade_id", null: false
    t.integer "source_trade_id"
    t.decimal "quantity", precision: 15, scale: 2
    t.decimal "amount", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_gain_losses_on_account_id"
    t.index ["source_trade_id"], name: "index_gain_losses_on_source_trade_id"
    t.index ["trade_id"], name: "index_gain_losses_on_trade_id"
  end

  create_table "securities", force: :cascade do |t|
    t.string "name"
    t.string "symbol"
    t.integer "currency_id"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_securities_on_user_id"
  end

  create_table "trades", force: :cascade do |t|
    t.date "date"
    t.integer "account_id", null: false
    t.integer "security_id", null: false
    t.decimal "price", precision: 15, scale: 5
    t.decimal "quantity", precision: 15, scale: 2
    t.decimal "fee", precision: 15, scale: 2
    t.decimal "other", precision: 15, scale: 2
    t.decimal "amount", precision: 15, scale: 2
    t.decimal "quantity_balance", precision: 15, scale: 5
    t.decimal "quantity_tax_balance", precision: 15, scale: 5
    t.decimal "cost_tax_balance", precision: 15, scale: 2
    t.string "trade_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "split_new_shares"
    t.integer "conversion_to_security_id"
    t.decimal "conversion_to_quantity"
    t.decimal "conversion_from_quantity"
    t.index ["account_id", "security_id"], name: "index_trades_on_account_id_and_security_id"
    t.index ["account_id"], name: "index_trades_on_account_id"
    t.index ["security_id"], name: "index_trades_on_security_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", limit: 128, null: false
    t.string "confirmation_token", limit: 128
    t.string "remember_token", limit: 128, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token", unique: true
  end

  add_foreign_key "gain_losses", "accounts"
  add_foreign_key "trades", "accounts"
  add_foreign_key "trades", "securities"
end
