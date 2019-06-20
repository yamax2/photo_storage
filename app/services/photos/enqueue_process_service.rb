module Photos
  class EnqueueProcessService
    include ::Interactor

    delegate :rubric_id, :uploaded_io, :photo, to: :context

    def call
      context.photo = Photo.new(photo_attributes)

      context.fail! unless photo.save

      ProcessFileJob.perform_async(photo.id)
    end

    private

    def move_temp_file
      dir = Rails.root.join('tmp', 'files')
      local_filename = SecureRandom.hex(26)

      FileUtils.mkdir_p(dir)
      FileUtils.mv(uploaded_io.tempfile, dir.join(local_filename))

      local_filename
    end

    def photo_attributes
      {
        size: uploaded_io.size,
        content_type: uploaded_io.content_type,
        original_filename: uploaded_io.original_filename,
        name: uploaded_io.original_filename,
        rubric_id: rubric_id,
        local_filename: move_temp_file
      }
    end
  end
end
