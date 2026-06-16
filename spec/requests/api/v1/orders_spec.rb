# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Orders', type: :request do
  let(:user) { create(:user) }
  let!(:account) { create(:account, user: user, balance_cents: 0, currency: 'EUR') }

  describe 'POST /api/v1/orders' do
    context 'with valid params' do
      it 'creates an order in the created status, inheriting the account currency' do
        expect do
          post '/api/v1/orders', params: { order: { user_id: user.id, amount_cents: 1500 } }, as: :json
        end.to change(Order, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response).to include(user_id: user.id, amount_cents: 1500, currency: 'EUR', status: 'created')
      end

      it 'moves no money (no ledger entry, balance unchanged)' do
        expect do
          post '/api/v1/orders', params: { order: { user_id: user.id, amount_cents: 1500 } }, as: :json
        end.to not_change(Transaction, :count).and(not_change { account.reload.balance_cents })
      end
    end

    context 'with invalid params' do
      it 'returns 422 when amount is non-positive' do
        post '/api/v1/orders', params: { order: { user_id: user.id, amount_cents: 0 } }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns 422 when the user does not exist' do
        post '/api/v1/orders', params: { order: { user_id: 0, amount_cents: 1500 } }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /api/v1/orders/:id' do
    it 'returns the order' do
      order = create(:order, user: user, amount_cents: 800)

      get "/api/v1/orders/#{order.id}"

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(id: order.id, amount_cents: 800, status: 'created')
    end

    it 'returns 404 for a missing order' do
      get '/api/v1/orders/0'

      expect(response).to have_http_status(:not_found)
    end
  end
end
