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
        @rubrics = Rubric.where(rubric_id: @rubric&.id)

        @rubrics =
          if params[:ord] == 'first_photo'
            @rubrics.by_first_photo
          else
            @rubrics.default_order
          end

        redirect_to admin_rubrics_positions_path unless @rubrics.count > 1
      end

      private

      def find_rubric
        @rubric = Rubric.find(params[:id]) if params[:id].present?
      end
    end
  end
end
