# frozen_string_literal: true

require 'net/http'

module Nominatim
  # Reverse Geocode
  # http://nominatim.org/release-docs/latest/api/Reverse/
  # https://operations.osmfoundation.org/policies/nominatim/
  class ReverseGeocode
    ACTION_URL = 'https://nominatim.openstreetmap.org/reverse'
    USER_AGENT = 'PhotoStorage https://github.com/yamax2/photo_storage'

    delegate :config, to: YandexClient, private: true

    class Error < StandardError
      attr_reader :code, :error_text

      def initialize(error_text:, code: nil)
        @code = code
        @error_text = error_text

        super "nominatim request failed: #{@error_text}, code: #{@code}"
      end
    end

    def initialize(lat:, long:)
      @lat = lat
      @long = long
    end

    def call
      response = make_request

      raise Error.new(error_text: response.body, code: response.code.to_i) unless response.status.success?

      body = JSON.parse(response.body, symbolize_names: true)

      if (error = body[:error]).present?
        raise Error.new(error_text: error)
      end

      body
    end

    private

    def make_request
      HTTP.
        timeout(
          connect: config.connect_timeout,
          read: config.read_timeout,
          write: config.write_timeout
        ).
        get(
          request_url,
          headers: {'User-Agent' => USER_AGENT}
        )
    end

    def request_url
      "#{ACTION_URL}?format=jsonv2&lat=#{@lat}&lon=#{@long}&accept-language=" \
        "#{Rails.application.config.i18n.default_locale}"
    end
  end
end
