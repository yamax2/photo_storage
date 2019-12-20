# frozen_string_literal: true

module Photos
  class EnqueueProcessService
    include ::Interactor

    delegate :uploaded_io, :model, to: :context

    def call
      model.assign_attributes(photo_attributes)

      context.fail! unless model.save

      ProcessFileJob.perform_async(model.id)
    end

    private

    def photo_attributes
      {
        size: uploaded_io.size,
        content_type: uploaded_io.content_type,
        original_filename: uploaded_io.original_filename,
        local_filename: UploadFileService.move(uploaded_io)
      }
    end
  end
end
