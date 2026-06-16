# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :user
  # Леджер защищаем: счёт с движениями нельзя удалить «мимо» истории
  has_many :transactions, inverse_of: :account, dependent: :restrict_with_exception

  validates :currency, presence: true
  validates :balance_cents, numericality: { greater_than_or_equal_to: 0 }
end
