module Cart
  # add to cart or remove photo
  class PhotoService
    include ::Interactor

    delegate :photo, :remove, to: :context

    def call
      return unless photo.persisted?

      key = "cart:photos:#{photo.rubric_id}"

      if remove
        redis.srem(key, photo.id)
      else
        redis.sadd(key, photo.id)
      end
    end

    delegate :redis, to: RedisClassy
  end
end
