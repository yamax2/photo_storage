# frozen_string_literal: true

module Api
  module V1
    class PagesController < BaseController
      def show
        @page = Page.new(params.require(:id), single_rubric_mode: true)

        @photos = @page.photos(
          offset: params[:offset].to_i,
          limit: params[:limit].to_i,
          only_with_geo_tags: params[:only_with_geo_tags]
        )
      end

      def summary
        @bounds = Rubrics::MapBoundsService.call!(
          rubric_id: params.require(:id)
        ).bounds
      end
    end
  end
end
