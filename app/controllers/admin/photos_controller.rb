module Admin
  class PhotosController < ::ActionController::API
    def create
      context = Photos::EnqueueProcessService.call(
        uploaded_io: params.require(:image),
        rubric_id: params.require(:rubric_id)
      )

      if context.success?
        sleep(10)
        render json: {}
      else
        render json: context.photo.errors, status: :unprocessable_entity
      end
    end
  end
end
