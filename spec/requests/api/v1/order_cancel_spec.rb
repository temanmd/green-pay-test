# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Order cancel', type: :request do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 2000, currency: 'EUR') }

  describe 'POST /api/v1/orders/:id/cancel' do
    context 'when the order was succeeded' do
      let(:order) { create(:order, user: user, amount_cents: 1500) }

      before do
        account
        Orders::Succeed.run!(order_id: order.id) # debits 2000 -> 500, status succeeded
      end

      it 'reverses the settlement and credits the account back' do
        expect do
          post "/api/v1/orders/#{order.id}/cancel", as: :json
        end.to change { order.reload.status }.from('succeeded').to('cancelled')
          .and change { account.reload.balance_cents }.from(500).to(2000)
          .and change(Transaction, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(id: order.id, status: 'cancelled')

        settlement = order.transactions.settlement.first
        reversal = Transaction.last
        expect(reversal).to have_attributes(kind: 'reversal', amount_cents: 1500, reverses_transaction_id: settlement.id)
      end
    end

    context 'when the order is still created' do
      let(:order) { create(:order, user: user, amount_cents: 1500) }

      it 'cancels without moving any money' do
        account
        expect do
          post "/api/v1/orders/#{order.id}/cancel", as: :json
        end.to change { order.reload.status }.from('created').to('cancelled')
          .and(not_change { account.reload.balance_cents })
          .and not_change(Transaction, :count)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the order is already cancelled' do
      let(:order) { create(:order, user: user, amount_cents: 1500, status: 'cancelled') }

      it 'returns 422' do
        account
        post "/api/v1/orders/#{order.id}/cancel", as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when the order does not exist' do
      it 'returns 404' do
        post '/api/v1/orders/0/cancel', as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
