# frozen_string_literal: true

module Api
  module V1
    module Admin
      class RubricsController < BaseController
        # rubrics list formatted for jstree
        def index
          @rubrics = Rubrics::FilterFinder.
            call(name_part: params[:str]).
            where(rubric_id: params[:id]).
            default_order
        end

        def update
          @rubric = Rubric.find(params[:id])
          @photo = @rubric.photos.find(params.require(:rubric).require(:main_photo_id))

          ::Rubrics::ApplyMainPhotoService.call!(
            rubric: @rubric,
            photo: @photo
          )
        end
      end
    end
  end
end
