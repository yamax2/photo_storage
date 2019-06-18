module Admin
  class PhotosController < AdminController
    layout false

    def create
      context = Photos::EnqueueProcessService.call(
        uploaded_io: params.require(:image),
        rubric_id: params.require(:rubric_id)
      )

      if context.success?
        render json: {}
      else
        render json: context.photo.errors, status: :unprocessable_entity
      end
    end
  end
end
