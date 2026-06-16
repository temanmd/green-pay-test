# frozen_string_literal: true

class UserSerializer < Panko::Serializer
  attributes :id, :name

  has_one :account, serializer: AccountSerializer
end
