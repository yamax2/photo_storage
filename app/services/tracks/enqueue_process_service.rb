# frozen_string_literal: true

module Tracks
  class EnqueueProcessService
    include ::Interactor

    delegate :model, :uploaded_io, to: :context

    def call
      assign_attributes
      validate_gpx

      if model.errors.empty? && model.save
        ProcessFileJob.perform_async(
          model.id,
          StorageFilenameGenerator.call(model, partition: false)
        )
      else
        context.fail!
      end
    end

    private

    def assign_attributes
      model.assign_attributes(
        local_filename: UploadedFileService.move(uploaded_io),
        original_filename: uploaded_io.original_filename,
        size: uploaded_io.size
      )
    end

    def validate_gpx
      return if uploaded_io.content_type == Track::MIME_TYPE

      model.errors.add(
        :content_type,
        I18n.t('activerecord.errors.models.track.attributes.content.wrong_value')
      )
    end
  end
end
