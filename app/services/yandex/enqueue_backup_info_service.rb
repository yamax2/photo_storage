# frozen_string_literal: true

module Yandex
  class EnqueueBackupInfoService
    include ::Interactor

    INFO_KEY_TTL = 5.minutes
    private_constant :INFO_KEY_TTL

    delegate :token, :resource, :info, to: :context

    def call
      unless BackupInfoService::RESOURCE_DIRS.key?(resource)
        raise BackupInfoService::WrongResourceError,
              "wrong resource passed: \"#{resource}\""
      end

      if (value = redis.get(redis_key)).present?
        context.info = value
        redis.del(redis_key)
      else
        try_to_enqueue_job
      end
    end

    private

    delegate :redis, to: RedisClassy, private: true

    def redis_key
      @redis_key ||= "backup_info:#{token.id}:#{resource}"
    end

    def try_to_enqueue_job
      return unless redis.set(redis_key, nil, nx: true, ex: INFO_KEY_TTL)

      BackupInfoJob.perform_async(
        token.id,
        resource,
        redis_key
      )
    end
  end
end
