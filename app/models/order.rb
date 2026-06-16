# frozen_string_literal: true

class Order < ApplicationRecord
  include AASM

  belongs_to :user
  has_one :account, through: :user
  has_many :transactions, inverse_of: :order, dependent: :restrict_with_exception

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :currency, presence: true

  # Статусы и допустимые переходы описаны декларативно. Сами события (succeed!/cancel!)
  # вызываются ИЗ команд (app/services), где в одной транзакции происходит и переход,
  # и проводка по леджеру. Никакой бизнес-логики в AR-колбэках.
  aasm column: :status do
    state :created, initial: true
    state :succeeded
    state :cancelled

    event :succeed do
      transitions from: :created, to: :succeeded
    end

    event :cancel do
      transitions from: %i[created succeeded], to: :cancelled
    end
  end
end
