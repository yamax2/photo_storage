# frozen_string_literal: true

module Api
  module V1
    class PagesController < BaseController
      def show
        @page = Page.new(
          params.require(:id),
          offset: params.require(:offset),
          limit: params.require(:limit),
          single_rubric_mode: true
        )
      end
    end
  end
end
