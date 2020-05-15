# frozen_string_literal: true

module Api
  module V1
    class TracksController < BaseController
      include ActionController::Cookies

      before_action :find_rubric

      def index
        @tracks = @rubric.tracks.uploaded.includes(:yandex_token).order(:started_at).decorate
      end

      private

      def find_rubric
        @rubric = Rubric.find(params[:rubric_id])
      end
    end
  end
end
