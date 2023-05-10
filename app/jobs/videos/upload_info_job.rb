# frozen_string_literal: true

module Videos
  class UploadInfoJob
    include Sidekiq::Worker

    INFO_KEY_TTL = 1.minute.to_i
    private_constant :INFO_KEY_TTL

    def perform(video_id, redis_key, skip_original)
      return if (video = Photo.videos.find_by(id: video_id)).nil?

      info = UploadInfoService.new(video, skip_original:).call

      Rails.application.redis.call(
        'SET',
        redis_key,
        info,
        ex: INFO_KEY_TTL
      )
    end
  end
end
