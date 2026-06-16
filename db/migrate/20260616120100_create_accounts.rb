class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      # Один счёт-кошелёк на юзера → уникальный индекс по user_id (связь 1:1)
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.bigint :balance_cents, null: false, default: 0
      t.string :currency, null: false, default: "EUR" # ISO 4217; деньги без валюты не храним

      t.timestamps
    end

    # Инвариант хранилища: кошелёк не может уйти в минус (defense-in-depth к проверке в команде)
    add_check_constraint :accounts, "balance_cents >= 0", name: "accounts_balance_non_negative"
  end
end
