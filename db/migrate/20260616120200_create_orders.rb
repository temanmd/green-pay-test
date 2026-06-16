class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "EUR"
      t.string :status, null: false, default: "created" # state-machine колонка (aasm)

      t.timestamps
    end

    add_index :orders, :status # будем выбирать заказы по статусу

    add_check_constraint :orders, "amount_cents > 0", name: "orders_amount_positive"
    # Статус — закрытое множество. БД-страховка к state-machine на уровне приложения.
    add_check_constraint :orders, "status IN ('created', 'succeeded', 'cancelled')", name: "orders_status_valid"
  end
end
