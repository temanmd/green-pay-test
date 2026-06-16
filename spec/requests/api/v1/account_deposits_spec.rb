# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Account deposits', type: :request do
  describe 'POST /api/v1/accounts/:id/deposit' do
    let(:user) { create(:user) }
    let(:account) { create(:account, user: user, balance_cents: 1000, currency: 'EUR') }

    context 'with a valid amount' do
      it 'increases the balance and records a deposit ledger entry' do
        expect do
          post "/api/v1/accounts/#{account.id}/deposit", params: { amount_cents: 500 }, as: :json
        end.to change { account.reload.balance_cents }.from(1000).to(1500)
          .and change(Transaction, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(id: account.id, balance_cents: 1500)

        txn = Transaction.last
        expect(txn).to have_attributes(kind: 'deposit', amount_cents: 500, account_id: account.id, order_id: nil)
      end
    end

    context 'with a non-positive amount' do
      it 'returns 422 and changes nothing' do
        expect do
          post "/api/v1/accounts/#{account.id}/deposit", params: { amount_cents: 0 }, as: :json
        end.to not_change { account.reload.balance_cents }.and not_change(Transaction, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when the account does not exist' do
      it 'returns 404' do
        post '/api/v1/accounts/0/deposit', params: { amount_cents: 500 }, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
