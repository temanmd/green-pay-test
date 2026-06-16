# frozen_string_literal: true

module Orders
  # Перевод заказа в успех = settlement: дебетуем кошелёк на сумму заказа и пишем
  # settlement-запись в леджер. Всё атомарно под локами (order → account).
  class Succeed < Mutations::Command
    required do
      integer :order_id
    end

    def execute
      order = Order.find(order_id)
      account = order.account
      return add_error(:account, :missing, 'User has no account') if account.nil?

      # FOR UPDATE на заказ: перезагружает статус и сериализует операции над заказом
      # (повторный success дождётся лока и увидит уже изменённый статус → 422, без двойного списания).
      order.with_lock do
        if !order.created?
          add_error(:order, :invalid_state, "Order cannot be succeeded from '#{order.status}'")
        elsif account.lock!.balance_cents < order.amount_cents
          # лочим счёт и читаем СВЕЖИЙ баланс под локом → нет lost-update/TOCTOU
          add_error(:funds, :insufficient, 'Insufficient funds')
        else
          Transaction.create!(order: order, account: account, kind: 'settlement', amount_cents: -order.amount_cents)
          account.update!(balance_cents: account.balance_cents - order.amount_cents)
          order.succeed!
        end
      end

      order
    end
  end
end
