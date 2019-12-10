# frozen_string_literal: true

module Api
  module V1
    module Admin
      class PhotosController < BaseController
        def create
          uploaded_io = params.require(:image)

          @photo = Photo.new(
            name: File.basename(uploaded_io.original_filename, '.*'),
            rubric: Rubric.find(params.require(:rubric_id))
          )

          context = ::Photos::EnqueueProcessService.call(
            photo: @photo,
            uploaded_io: uploaded_io,
            external_info: params[:external_info]
          )

          @success = context.success?

          render status: :unprocessable_entity unless @success
        end
      end
    end
  end
end
