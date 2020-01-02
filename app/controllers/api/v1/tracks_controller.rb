# frozen_string_literal: true

module Api
  module V1
    class TracksController < BaseController
      include ActionController::Cookies

      helper_method :current_session

      def index
        @rubric = Rubric.find(params[:page_id])
        @tracks = Track.uploaded.where(rubric: @rubric).includes(:yandex_token).order(id: :desc).decorate
      end

      private

      def current_session
        CGI.escape(cookies[:proxy_session])
      end
    end
  end
end
