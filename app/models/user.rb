# frozen_string_literal: true

class User < ApplicationRecord
  # Финансовую историю не удаляем: юзера со счётом/заказами нельзя снести «вникуда»
  has_one :account, inverse_of: :user, dependent: :restrict_with_exception
  has_many :orders, inverse_of: :user, dependent: :restrict_with_exception

  validates :name, presence: true
end
