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

ActiveRecord::Schema[8.1].define(version: 2026_06_16_120500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.bigint "balance_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_accounts_on_user_id", unique: true
    t.check_constraint "balance_cents >= 0", name: "accounts_balance_non_negative"
  end

  create_table "idempotency_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "request_digest", null: false
    t.text "response_body"
    t.integer "response_status"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_idempotency_keys_on_key", unique: true
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.string "status", default: "created", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "amount_cents > 0", name: "orders_amount_positive"
    t.check_constraint "status::text = ANY (ARRAY['created'::character varying, 'succeeded'::character varying, 'cancelled'::character varying]::text[])", name: "orders_status_valid"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.bigint "order_id"
    t.bigint "reverses_transaction_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["order_id", "kind"], name: "index_transactions_on_order_id_and_kind", unique: true
    t.index ["reverses_transaction_id"], name: "index_transactions_on_reverses_transaction_id"
    t.check_constraint "amount_cents <> 0", name: "transactions_amount_nonzero"
    t.check_constraint "kind::text = 'deposit'::text AND order_id IS NULL OR kind::text <> 'deposit'::text AND order_id IS NOT NULL", name: "transactions_order_presence"
    t.check_constraint "kind::text = ANY (ARRAY['deposit'::character varying, 'settlement'::character varying, 'reversal'::character varying]::text[])", name: "transactions_kind_valid"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "orders", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "orders"
  add_foreign_key "transactions", "transactions", column: "reverses_transaction_id"
end
