module Admin
  module Rubrics
    class PositionsController < AdminController
      def create
        ::Rubrics::ApplyOrder.call!(
          id: positions_params[:id].presence,
          data: positions_params.require(:data).split(',').map(&:to_i)
        )

        redirect_to admin_rubrics_path
      end

      def index
        @rubric = Rubric.find(params[:id]) if params[:id]
        @rubrics = (@rubric&.rubrics || Rubric.where(rubric_id: nil)).default_order

        redirect_to admin_rubrics_path unless @rubrics.count > 1
      end

      private

      def positions_params
        params.require(:positions).permit(:id, :data)
      end
    end
  end
end
