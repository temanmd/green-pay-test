class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :account, null: false, foreign_key: true
      # order_id индексируется составным уникальным индексом ниже, поэтому index: false
      t.references :order, null: false, foreign_key: true, index: false
      t.string :kind, null: false # 'settlement' | 'reversal'
      # Знаковая дельта, применяемая к балансу: settlement < 0 (списание), reversal > 0 (возврат).
      # Инвариант: accounts.balance_cents == SUM(transactions.amount_cents).
      t.bigint :amount_cents, null: false
      # reversal ссылается на settlement, который сторнирует (у settlement — NULL)
      t.references :reverses_transaction, foreign_key: { to_table: :transactions }

      t.timestamps
    end

    # Идемпотентность на уровне БД: не более одной settlement и одной reversal на заказ.
    # Повторный «успех»/«отмена» физически не вставит второй записи (упадёт на unique).
    add_index :transactions, %i[order_id kind], unique: true

    add_check_constraint :transactions, "kind IN ('settlement', 'reversal')", name: "transactions_kind_valid"
    add_check_constraint :transactions, "amount_cents <> 0", name: "transactions_amount_nonzero"
  end
end
