# frozen_string_literal: true

module Api
  # Базовый контроллер API: единообразные JSON-ответы об ошибках.
  class BaseController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable

    private

    def render_not_found(error)
      render json: { error: 'not_found', message: error.message }, status: :not_found
    end

    def render_unprocessable(error)
      render json: { errors: error.record.errors.full_messages }, status: :unprocessable_content
    end

    # Единый формат ответа на провал команды (mutations).
    def render_errors(outcome)
      render json: { errors: outcome.errors.message_list }, status: :unprocessable_content
    end
  end
end
