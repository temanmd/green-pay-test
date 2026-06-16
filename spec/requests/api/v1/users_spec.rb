# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  describe 'POST /api/v1/users' do
    context 'with valid params and an opening balance' do
      let(:params) { { user: { name: 'Alice', opening_balance_cents: 5000, currency: 'EUR' } } }

      it 'creates a user with a funded account' do
        post '/api/v1/users', params: params, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response).to include(name: 'Alice')
        expect(json_response[:account]).to include(balance_cents: 5000, currency: 'EUR')
      end

      it 'records the opening balance as a single deposit ledger entry' do
        expect { post '/api/v1/users', params: params, as: :json }.to change(Transaction, :count).by(1)

        txn = Transaction.last
        expect(txn).to have_attributes(kind: 'deposit', amount_cents: 5000, order_id: nil)
      end
    end

    context 'without an opening balance' do
      it 'creates a zero-balance account and writes no ledger entry' do
        expect do
          post '/api/v1/users', params: { user: { name: 'Carol' } }, as: :json
        end.not_to change(Transaction, :count)

        expect(response).to have_http_status(:created)
        expect(json_response[:account]).to include(balance_cents: 0)
      end
    end

    context 'with invalid params' do
      it 'returns 422 when name is blank' do
        post '/api/v1/users', params: { user: { name: '' } }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to have_key(:errors)
      end

      it 'returns 422 and writes nothing when opening_balance_cents is negative' do
        expect do
          post '/api/v1/users', params: { user: { name: 'Dave', opening_balance_cents: -100 } }, as: :json
        end.to not_change(User, :count).and not_change(Transaction, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /api/v1/users/:id' do
    it 'returns the user with the account balance' do
      user = create(:user)
      create(:account, user: user, balance_cents: 1200, currency: 'EUR')

      get "/api/v1/users/#{user.id}"

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(id: user.id, name: user.name)
      expect(json_response[:account]).to include(balance_cents: 1200, currency: 'EUR')
    end

    it 'returns 404 for a missing user' do
      get '/api/v1/users/0'

      expect(response).to have_http_status(:not_found)
    end
  end
end
