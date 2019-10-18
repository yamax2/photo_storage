# frozen_string_literal: true

module Photos
  class LoadDescriptionService
    include ::Interactor

    delegate :photo, to: :context

    def call
      return if photo.description.present? || photo.lat_long.nil?

      photo.update!(description: response.fetch(:display_name))
    end

    private

    def response
      @response ||= ::Nominatim::ReverseGeocode.new(
        lat: photo.lat_long.x,
        long: photo.lat_long.y
      ).call
    end
  end
end
