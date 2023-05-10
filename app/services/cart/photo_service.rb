# frozen_string_literal: true

module Cart
  # add to cart or remove photo
  class PhotoService
    include ::Interactor

    delegate :photo, :remove, to: :context

    def call
      return unless photo.persisted?

      key = "cart:photos:#{photo.rubric_id}"

      if remove
        redis.call('SREM', key, photo.id)
      else
        redis.call('SADD', key, photo.id)
      end
    end

    delegate :redis, to: 'Rails.application', private: true
  end
end
