# frozen_string_literal: true

require 'net/http'

module Rubrics
  class WarmUpJob
    include Sidekiq::Worker

    def perform(rubric_id, photo_size)
      validate_photo_size(photo_size)

      Rubric.
        find(rubric_id).
        photos.uploaded.order(:id).
        each_instance(with_lock: true) do |photo|
        warm_photo_cache(photo.decorate, photo_size.to_sym)
      end
    end

    private

    def http(url)
      uri = URI.parse(url)

      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = Rails.application.routes.default_url_options[:protocol].to_s == 'https'
        http.read_timeout = 30
      end
    end

    def validate_photo_size(photo_size)
      keys = Rails.application.config.photo_sizes.keys - [:thumb]

      raise "wrong photo size #{photo_size}" unless keys.include?(photo_size.to_sym)
    end

    def warm_photo_cache(photo, photo_size)
      url = photo.url(photo_size)
      request = Net::HTTP::Get.new(url)

      http(url).request(request) do |response|
        raise "warming up error on photo id #{photo.id}" unless response.is_a?(Net::HTTPOK)
      end
    end
  end
end
