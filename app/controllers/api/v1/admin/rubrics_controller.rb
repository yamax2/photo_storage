module Api
  module V1
    module Admin
      # rubrics list formatted for jstree
      class RubricsController < ::ActionController::API
        def index
          @rubrics = Rubric.where(rubric_id: params[:id]).default_order
        end
      end
    end
  end
end
