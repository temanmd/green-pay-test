# frozen_string_literal: true

module Api
  module V1
    class UsersController < Api::BaseController
      def show
        render_user(params[:id])
      end

      def create
        outcome = Users::Create.run(user_params)
        return render_errors(outcome) unless outcome.success?

        render_user(outcome.result.id, status: :created)
      end

      private

      def user_params
        params.expect(user: %i[name opening_balance_cents currency]).to_h
      end

      def render_user(id, status: :ok)
        user = User.includes(:account).find(id)
        render json: UserSerializer.new.serialize_to_json(user), status: status
      end

      def render_errors(outcome)
        render json: { errors: outcome.errors.message_list }, status: :unprocessable_content
      end
    end
  end
end
