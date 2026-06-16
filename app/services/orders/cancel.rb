# frozen_string_literal: true

module Orders
  # Отмена заказа. Если заказ был успешным — сторнируем: пишем компенсирующую reversal-запись
  # (ссылается на исходный settlement) и возвращаем деньги на счёт. Если заказ ещё `created` —
  # просто отменяем, денег не двигаем. Append-only: исходный settlement не трогаем.
  class Cancel < Mutations::Command
    required do
      integer :order_id
    end

    def execute
      order = Order.find(order_id)
      account = order.account
      return add_error(:account, :missing, 'User has no account') if account.nil?

      order.with_lock do
        if order.cancelled?
          add_error(:order, :invalid_state, "Order cannot be cancelled from 'cancelled'")
        elsif order.succeeded?
          reverse_settlement(order, account)
          order.cancel!
        else # created → отмена без проводки
          order.cancel!
        end
      end

      order
    end

    private

    def reverse_settlement(order, account)
      settlement = order.transactions.settlement.first!
      reversal_amount = -settlement.amount_cents # settlement < 0 → reversal > 0 (возврат)

      account.lock!
      Transaction.create!(
        order: order, account: account, kind: 'reversal',
        amount_cents: reversal_amount, reverses_transaction: settlement
      )
      account.update!(balance_cents: account.balance_cents + reversal_amount)
    end
  end
end
