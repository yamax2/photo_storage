# frozen_string_literal: true

module Api
  module V1
    class RubricsController < BaseController
      def show
        @photos = Rubrics::PhotosFinder.call(
          params.require(:id),
          offset: params[:offset].to_i,
          limit: params[:limit].to_i,
          only_with_geo_tags: params[:only_with_geo_tags]
        ).decorate
      end

      def summary
        @bounds = Rubrics::MapBoundsService.call!(
          rubric_id: params.require(:id)
        ).bounds
      end
    end
  end
end
