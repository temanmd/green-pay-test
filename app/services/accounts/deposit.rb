# frozen_string_literal: true

module Accounts
  # Пополнение счёта: пишет deposit-запись в леджер и увеличивает баланс под строчной
  # блокировкой (SELECT ... FOR UPDATE) — нет lost-update при конкурентных пополнениях.
  class Deposit < Mutations::Command
    required do
      model :account
      integer :amount_cents, min: 1
    end

    def execute
      account.with_lock do
        transaction = account.transactions.create!(kind: 'deposit', amount_cents: amount_cents)
        account.update!(balance_cents: account.balance_cents + amount_cents)
        transaction
      end
    end
  end
end
