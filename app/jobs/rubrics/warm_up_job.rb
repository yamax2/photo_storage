# frozen_string_literal: true

module Rubrics
  class WarmUpJob
    include Sidekiq::Worker

    def perform(rubric_id, photo_size)
      validate_photo_size(photo_size)

      Rubric.
        find(rubric_id).
        photos.uploaded.
        order(:id).
        each_instance { |photo| warm_up_photo(photo.decorate, photo_size.to_sym) }
    end

    private

    delegate :default_url_options, to: 'Rails.application.routes', private: true
    delegate :config, to: YandexClient, private: true

    def validate_photo_size(photo_size)
      keys = Rails.application.config.photo_sizes.keys - [:thumb]

      raise "wrong photo size: #{photo_size}" unless keys.include?(photo_size.to_sym)
    end

    def warm_up_photo(photo, photo_size)
      path = photo.proxy_url(photo_size)
      url = Addressable::URI.new(
        scheme: default_url_options.fetch(:protocol), host: default_url_options.fetch(:host), path:
      )

      HTTP.
        timeout(
          connect: config.connect_timeout,
          read: config.read_timeout,
          write: config.write_timeout
        ).get(url.to_s)
    end
  end
end
