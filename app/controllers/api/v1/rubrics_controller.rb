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
        @bounds = Rubrics::MapBoundsService.new(
          params.require(:id),
          only_videos: to_bool(params[:only_videos])
        ).call
      end

      private

      def find_objects
        @listing = Rubrics::Listing.new(
          params[:id],
          listing_params
        ).to_a
      end

      def listing_params
        {
          offset: params[:offset].to_i,
          limit: params[:limit].to_i,
          only_with_geo_tags: to_bool(params[:only_with_geo_tags]),
          only_videos: to_bool(params[:only_videos]),
          desc_order: to_bool(params[:desc_order])
        }
      end

      def to_bool(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
