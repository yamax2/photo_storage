# frozen_string_literal: true

module Photos
  class EnqueueLoadDescriptionService
    include ::Interactor

    delegate :photo, to: :context, private: true

    def call
      return if photo.description.present? || photo.lat_long.nil?

      LoadDescriptionJob.perform_async(photo.id)
    end
  end
end
