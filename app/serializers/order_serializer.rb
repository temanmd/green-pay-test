# frozen_string_literal: true

class OrderSerializer < Panko::Serializer
  attributes :id, :user_id, :amount_cents, :currency, :status
end
