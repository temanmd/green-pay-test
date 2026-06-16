# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Order success', type: :request do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 2000, currency: 'EUR') }
  let(:order) { create(:order, user: user, amount_cents: 1500, currency: 'EUR') }

  describe 'POST /api/v1/orders/:id/success' do
    context 'when the order is created and funds are sufficient' do
      it 'succeeds the order and debits the account via a settlement entry' do
        account
        expect do
          post "/api/v1/orders/#{order.id}/success", as: :json
        end.to change { order.reload.status }.from('created').to('succeeded')
          .and change { account.reload.balance_cents }.from(2000).to(500)
          .and change(Transaction, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(id: order.id, status: 'succeeded')

        txn = Transaction.last
        expect(txn).to have_attributes(kind: 'settlement', amount_cents: -1500, order_id: order.id, account_id: account.id)
      end
    end

    context 'when funds are insufficient' do
      let(:account) { create(:account, user: user, balance_cents: 1000, currency: 'EUR') }

      it 'returns 422 and changes nothing' do
        account
        expect do
          post "/api/v1/orders/#{order.id}/success", as: :json
        end.to not_change { order.reload.status }
          .and(not_change { account.reload.balance_cents })
          .and not_change(Transaction, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when the order is already succeeded' do
      it 'does not debit twice and returns 422' do
        account
        post "/api/v1/orders/#{order.id}/success", as: :json
        expect(order.reload).to be_succeeded

        expect do
          post "/api/v1/orders/#{order.id}/success", as: :json
        end.to not_change { account.reload.balance_cents }.and not_change(Transaction, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when the order is cancelled' do
      let(:order) { create(:order, user: user, amount_cents: 1500, status: 'cancelled') }

      it 'returns 422' do
        account
        post "/api/v1/orders/#{order.id}/success", as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when the order does not exist' do
      it 'returns 404' do
        post '/api/v1/orders/0/success', as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
