module Photos
  class EnqueueLoadDescriptionService
    include ::Interactor

    delegate :photo, to: :context

    def call
      return if photo.description.present? || photo.lat_long.nil?

      LoadDescriptionJob.perform_async(photo.id)
    end
  end
end
