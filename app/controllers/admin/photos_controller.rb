module Admin
  class PhotosController < ::ActionController::API
    def create
      context = Photos::EnqueueProcessService.call(
        uploaded_io: params.require(:image),
        rubric_id: params.require(:rubric_id),
        external_info: params[:external_info]
      )

      @success = context.success?
      @photo = context.photo

      render status: :unprocessable_entity unless @success
    end
  end
end
