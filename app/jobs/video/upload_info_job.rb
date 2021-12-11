# frozen_string_literal: true

module Video
  class UploadInfoJob
    include Sidekiq::Worker

    INFO_KEY_TTL = 1.minute
    private_constant :INFO_KEY_TTL

    def perform(video_id, redis_key)
      video = Photo.video.find(video_id)
      info = UploadInfoService.new(video).call

      RedisClassy.redis.set(
        redis_key,
        info,
        ex: INFO_KEY_TTL
      )
    end
  end
end
