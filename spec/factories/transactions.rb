# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    order
    # account должен принадлежать тому же юзеру, что и заказ
    account { order.user.account || create(:account, user: order.user) }
    kind { 'settlement' }
    amount_cents { -order.amount_cents }
  end
end
