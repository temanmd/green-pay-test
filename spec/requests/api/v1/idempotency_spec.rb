# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HTTP Idempotency-Key', type: :request do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 1000, currency: 'EUR') }
  let(:key) { SecureRandom.uuid }
  let(:headers) { { 'Idempotency-Key' => key } }

  describe 'replaying the same POST with the same key' do
    it 'executes once and returns the stored response on retry' do
      account

      expect do
        post "/api/v1/accounts/#{account.id}/deposit", params: { amount_cents: 500 }, headers: headers, as: :json
      end.to change { account.reload.balance_cents }.by(500).and change(Transaction, :count).by(1)

      first_status = response.status
      first_body = response.body

      expect do
        post "/api/v1/accounts/#{account.id}/deposit", params: { amount_cents: 500 }, headers: headers, as: :json
      end.to not_change { account.reload.balance_cents }.and not_change(Transaction, :count)

      expect(response.status).to eq(first_status)
      expect(response.body).to eq(first_body)
    end
  end

  describe 'replaying a state transition (the payment-retry case)' do
    let(:order) { create(:order, user: user, amount_cents: 500) }

    it 'returns the original 200 on retry instead of a 422' do
      account

      post "/api/v1/orders/#{order.id}/success", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      original_body = response.body

      expect do
        post "/api/v1/orders/#{order.id}/success", headers: headers, as: :json
      end.to not_change(Transaction, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(original_body)
    end
  end

  describe 'reusing a key for a different request' do
    it 'returns 422 without executing' do
      account

      post "/api/v1/accounts/#{account.id}/deposit", params: { amount_cents: 500 }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)

      expect do
        post "/api/v1/accounts/#{account.id}/deposit", params: { amount_cents: 999 }, headers: headers, as: :json
      end.to(not_change { account.reload.balance_cents })

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'without an Idempotency-Key' do
    it 'executes every time' do
      account

      expect do
        2.times { post "/api/v1/accounts/#{account.id}/deposit", params: { amount_cents: 100 }, as: :json }
      end.to change(Transaction, :count).by(2)
    end
  end
end
