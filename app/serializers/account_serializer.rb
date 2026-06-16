# frozen_string_literal: true

class AccountSerializer < Panko::Serializer
  attributes :id, :balance_cents, :currency
end
