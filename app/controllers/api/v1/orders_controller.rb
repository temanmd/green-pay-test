# frozen_string_literal: true

module Api
  module V1
    class OrdersController < Api::BaseController
      def show
        order = Order.find(params.expect(:id))
        render json: OrderSerializer.new.serialize_to_json(order)
      end

      def create
        outcome = Orders::Create.run(order_params)
        return render_errors(outcome) unless outcome.success?

        render json: OrderSerializer.new.serialize_to_json(outcome.result), status: :created
      end

      def success
        outcome = Orders::Succeed.run(order_id: params.expect(:id))
        return render_errors(outcome) unless outcome.success?

        render json: OrderSerializer.new.serialize_to_json(outcome.result)
      end

      def cancel
        outcome = Orders::Cancel.run(order_id: params.expect(:id))
        return render_errors(outcome) unless outcome.success?

        render json: OrderSerializer.new.serialize_to_json(outcome.result)
      end

      private

      def order_params
        params.expect(order: %i[user_id amount_cents]).to_h
      end
    end
  end
end
