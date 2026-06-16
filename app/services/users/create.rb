# frozen_string_literal: true

module Users
  # Создаёт юзера и его счёт-кошелёк. Если задан стартовый баланс — кладём его первой
  # deposit-записью, чтобы инвариант balance == SUM(transactions.amount_cents) держался
  # с самого начала (а не «магическим» балансом мимо леджера).
  class Create < Mutations::Command
    required do
      string :name
    end

    optional do
      integer :opening_balance_cents, default: 0, min: 0
      string :currency, default: 'EUR'
    end

    def execute
      ActiveRecord::Base.transaction do
        user = User.create!(name: name)
        account = Account.create!(user: user, currency: currency, balance_cents: 0)
        Accounts::Deposit.run!(account: account, amount_cents: opening_balance_cents) if opening_balance_cents.positive?
        user
      end
    end
  end
end
