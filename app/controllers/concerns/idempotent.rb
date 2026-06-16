# frozen_string_literal: true

require 'digest'

# HTTP-идемпотентность по заголовку `Idempotency-Key` (опционально, как у Stripe).
# Применяется только к POST с заголовком: первый запрос выполняется и его ответ
# сохраняется; повтор с тем же ключом и тем же телом отдаёт сохранённый ответ,
# с другим телом → 422, «в процессе» → 409.
module Idempotent
  extend ActiveSupport::Concern

  HEADER = 'Idempotency-Key'

  included do
    around_action :apply_idempotency
  end

  private

  def apply_idempotency(&)
    return yield unless request.post?

    key = request.headers[HEADER]
    return yield if key.blank?

    digest = idempotency_request_digest

    existing = IdempotencyKey.find_by(key: key)
    return replay_idempotent(existing, digest) if existing

    record = claim_idempotency_key(key, digest)
    return replay_idempotent(IdempotencyKey.find_by!(key: key), digest) if record.nil?

    persist_idempotent_response(record, &)
  end

  # Атомарно «занимаем» ключ. Если параллельный запрос успел первым → nil (пусть ретраит/реплеит).
  def claim_idempotency_key(key, digest)
    IdempotencyKey.create!(key: key, request_digest: digest)
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def replay_idempotent(record, digest)
    if record.request_digest != digest
      return render json: { error: 'idempotency_key_conflict',
                            message: 'Idempotency-Key was reused with a different request' },
                    status: :unprocessable_content
    end

    unless record.completed?
      return render json: { error: 'idempotency_in_progress',
                            message: 'A request with this Idempotency-Key is still being processed' },
                    status: :conflict
    end

    render json: record.response_body, status: record.response_status
  end

  def persist_idempotent_response(record)
    yield

    # 5xx считаем не финальным результатом → даём возможность повторить (запись удаляем).
    if response.server_error?
      record.destroy
    else
      record.update!(response_status: response.status, response_body: response.body)
    end
  rescue StandardError
    record.destroy
    raise
  end

  def idempotency_request_digest
    Digest::SHA256.hexdigest([request.request_method, request.path, request.raw_post].join('|'))
  end
end
