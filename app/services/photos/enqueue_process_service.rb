# frozen_string_literal: true

module Photos
  class EnqueueProcessService
    include ::Interactor

    delegate :rubric_id, :external_info, :uploaded_io, :photo, to: :context

    def call
      context.photo = Photo.new(photo_attributes)

      context.fail! unless photo.save

      ProcessFileJob.perform_async(photo.id)
    end

    private

    def photo_attributes
      {
        size: uploaded_io.size,
        content_type: uploaded_io.content_type,
        original_filename: uploaded_io.original_filename,
        name: File.basename(uploaded_io.original_filename, '.*'),
        rubric_id: rubric_id,
        local_filename: UploadFileService.move(uploaded_io),
        external_info: external_info
      }
    end
  end
end
