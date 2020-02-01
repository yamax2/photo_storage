# frozen_string_literal: true

module Yandex
  class BackupInfoJob
    include Sidekiq::Worker
    sidekiq_options queue: :tokens

    INFO_KEY_TTL = 1.minute

    def perform(token_id, resource, redis_key)
      token = Yandex::Token.find(token_id)
      info = BackupInfoService.call!(token: token, resource: resource).info

      RedisClassy.redis.set(redis_key, info, ex: INFO_KEY_TTL)
    end
  end
end
