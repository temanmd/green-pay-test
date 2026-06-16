class AllowDepositTransactions < ActiveRecord::Migration[8.1]
  def up
    # Депозит (пополнение) не привязан к заказу → order_id становится nullable.
    change_column_null :transactions, :order_id, true

    remove_check_constraint :transactions, name: "transactions_kind_valid"
    add_check_constraint :transactions, "kind IN ('deposit', 'settlement', 'reversal')", name: "transactions_kind_valid"

    # Связка: deposit ⇔ нет заказа; settlement/reversal ⇔ заказ есть.
    add_check_constraint :transactions,
                         "(kind = 'deposit' AND order_id IS NULL) OR (kind <> 'deposit' AND order_id IS NOT NULL)",
                         name: "transactions_order_presence"
  end

  def down
    remove_check_constraint :transactions, name: "transactions_order_presence"
    remove_check_constraint :transactions, name: "transactions_kind_valid"
    add_check_constraint :transactions, "kind IN ('settlement', 'reversal')", name: "transactions_kind_valid"
    change_column_null :transactions, :order_id, false
  end
end
