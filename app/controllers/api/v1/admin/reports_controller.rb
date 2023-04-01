# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ReportsController < AdminController
        def show
          @rows = ReportQuery.new(params[:id]&.to_sym)
        end
      end
    end
  end
end
