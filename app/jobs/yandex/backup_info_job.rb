# frozen_string_literal: true

module Yandex
  class BackupInfoJob
    include Sidekiq::Worker
    sidekiq_options queue: :tokens

    INFO_KEY_TTL = 1.minute

    def perform(token_id, resource, folder_index, redis_key)
      token = Yandex::Token.find(token_id)

      info = BackupInfoService.call!(
        token:,
        resource:,
        folder_index:,
        backup_secret: Rails.application.credentials.backup_secret
      ).info

      RedisClassy.redis.set(redis_key, info, ex: INFO_KEY_TTL)
    end
  end
end
