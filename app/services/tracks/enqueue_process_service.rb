# frozen_string_literal: true

module Tracks
  class EnqueueProcessService
    include ::Interactor

    delegate :track, :uploaded_io, to: :context

    def call
      assign_attributes
      validate_gpx

      if track.errors.empty? && track.save
        # perform job here
      else
        fail_context
      end
    end

    private

    def assign_attributes
      track.assign_attributes(
        local_filename: UploadFileService.move(uploaded_io),
        original_filename: uploaded_io.original_filename,
        size: uploaded_io.size
      )
    end

    def fail_context
      FileUtils.rm_f(Rails.root.join('tmp', 'files', track.local_filename))
      context.fail!
    end

    def validate_gpx
      return if uploaded_io.content_type == Track::MIME_TYPE

      track.errors.add(
        :content,
        I18n.t('activerecord.errors.models.track.attributes.content.wrong_value')
      )
    end
  end
end
