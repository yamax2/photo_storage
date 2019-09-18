module Admin
  module Rubrics
    class PositionsController < AdminController
      before_action :find_rubric

      def create
        ::Rubrics::ApplyOrder.call!(
          id: @rubric&.id,
          data: params.require(:data).split(',').map(&:to_i)
        )

        redirect_to admin_rubrics_positions_path(id: @rubric&.id)
      end

      def index
        @rubrics = (@rubric&.rubrics || Rubric.where(rubric_id: nil)).default_order

        redirect_to admin_rubrics_positions_path unless @rubrics.count > 1
      end

      private

      def find_rubric
        @rubric = Rubric.find(params[:id]) if params[:id].present?
      end
    end
  end
end
