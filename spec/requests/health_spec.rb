# frozen_string_literal: true

require 'rails_helper'

# Тривиальная спека: проверяет, что request-инфраструктура и БД-подключение работают
# (грузится rails_helper, доступен get, отвечает health-эндпоинт Rails).
RSpec.describe 'Health check', type: :request do
  describe 'GET /up' do
    it 'returns 200 OK' do
      get '/up'

      expect(response).to have_http_status(:ok)
    end
  end
end
