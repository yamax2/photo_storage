# frozen_string_literal: true

module Api
  module V1
    class TracksController < BaseController
      include ActionController::Cookies

      helper_method :current_session
      before_action :find_rubric

      def index
        @tracks = @rubric.tracks.uploaded.includes(:yandex_token).order(:started_at).decorate
      end

      private

      def current_session
        CGI.escape(cookies[:proxy_session])
      end

      def find_rubric
        @rubric = Rubric.find(params[:page_id])
      end
    end
  end
end
