# frozen_string_literal: true

# Хранит результат первого выполнения запроса с данным Idempotency-Key,
# чтобы безопасно отдавать тот же ответ при ретраях (таймауты, повторные клики).
class IdempotencyKey < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :request_digest, presence: true

  # Запрос завершён, если сохранён статус ответа (иначе он «в процессе»).
  def completed?
    response_status.present?
  end
end
