# frozen_string_literal: true

module Api
  module V1
    class TracksController < BaseController
      def index
        @rubric = Rubric.find(params[:page_id])
        @tracks = Track.uploaded.where(rubric: @rubric).includes(:yandex_token).order(id: :desc).decorate
      end
    end
  end
end
