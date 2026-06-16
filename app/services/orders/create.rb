# frozen_string_literal: true

module Orders
  # Создаёт заказ в статусе `created`. Денег не двигает (это делает перевод в success).
  # Валюту наследует от счёта юзера, чтобы не было кросс-валютных заказов.
  class Create < Mutations::Command
    required do
      integer :user_id
      integer :amount_cents, min: 1
    end

    def execute
      user = User.find_by(id: user_id)
      return add_error(:user_id, :not_found, 'User not found') if user.nil?

      account = user.account
      return add_error(:account, :missing, 'User has no account') if account.nil?

      Order.create!(user: user, amount_cents: amount_cents, currency: account.currency)
    end
  end
end
