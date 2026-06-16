# frozen_string_literal: true

module Api
  module V1
    class AccountsController < Api::BaseController
      # POST /api/v1/accounts/:id/deposit — пополнение кошелька
      def deposit
        account = Account.find(params.expect(:id))
        outcome = Accounts::Deposit.run(account: account, amount_cents: params[:amount_cents])
        return render_errors(outcome) unless outcome.success?

        render json: AccountSerializer.new.serialize_to_json(account.reload)
      end
    end
  end
end
