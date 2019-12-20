# frozen_string_literal: true

module Tracks
  class EnqueueProcessService
    include ::Interactor

    delegate :model, :uploaded_io, to: :context

    def call
      assign_attributes
      validate_gpx

      if model.errors.empty? && model.save
        ProcessFileJob.perform_async(model.id)
      else
        fail_context
      end
    end

    private

    def assign_attributes
      model.assign_attributes(
        local_filename: UploadFileService.move(uploaded_io),
        original_filename: uploaded_io.original_filename,
        size: uploaded_io.size
      )
    end

    def fail_context
      FileUtils.rm_f(Rails.root.join('tmp', 'files', model.local_filename))
      context.fail!
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
