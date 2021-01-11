# frozen_string_literal: true

module Api
  module V1
    class RubricsController < BaseController
      before_action :find_objects, only: %i[show index]

      def index
        render :show
      end

      def show
      end

      def summary
        @bounds = Rubrics::MapBoundsService.call!(
          rubric_id: params.require(:id)
        ).bounds
      end

      private

      def find_objects
        @listing = Rubrics::Listing.new(
          params[:id],
          offset: params[:offset].to_i,
          limit: params[:limit].to_i,
          only_with_geo_tags: params[:only_with_geo_tags]
        ).to_a
      end
    end
  end
end
