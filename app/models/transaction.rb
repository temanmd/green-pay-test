# frozen_string_literal: true

# Запись леджера. Append-only: создаётся один раз и больше не меняется.
# Знак amount_cents задаёт направление: settlement < 0 (списание), reversal > 0 (возврат).
class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :order
  # reversal указывает на settlement, который сторнирует; у settlement — nil
  belongs_to :reverses_transaction, class_name: 'Transaction', optional: true

  enum :kind, { settlement: 'settlement', reversal: 'reversal' }

  validates :amount_cents, numericality: { other_than: 0 }

  # Неизменяемость леджера: разрешаем INSERT новой записи, запрещаем UPDATE существующей.
  def readonly?
    persisted?
  end
end
