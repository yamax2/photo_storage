require 'net/http'

module Rubrics
  class WarmUpJob
    include Sidekiq::Worker

    def perform(rubric_id, photo_size)
      Rubric.
        find(rubric_id).
        photos.uploaded.
        each_instance(with_lock: true) do |photo|
        warm_photo_cache(photo.decorate, photo_size.to_sym)
      end
    end

    private

    def warm_photo_cache(photo, photo_size)
      url = photo.url(photo_size)
      uri = URI.parse(url)

      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new(url)

        http.request(request) do |response|
          raise "warming up error on photo id #{photo.id}" unless response.is_a?(Net::HTTPOK)
        end
      end
    end
  end
end
