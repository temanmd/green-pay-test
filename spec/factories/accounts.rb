# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    user
    balance_cents { 0 }
    currency { 'EUR' }
  end
end
