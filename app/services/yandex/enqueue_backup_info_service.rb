# frozen_string_literal: true

module Yandex
  class EnqueueBackupInfoService
    include ::Interactor

    INFO_KEY_TTL = 5.minutes.to_i
    private_constant :INFO_KEY_TTL

    delegate :token, :resource, :folder_index, :info, to: :context

    def call
      unless BackupInfoService::RESOURCE_DIRS.key?(resource)
        raise BackupInfoService::WrongResourceError,
              "wrong resource passed: \"#{resource}\""
      end

      if (value = redis.call('GET', redis_key)).present?
        context.info = value
        redis.call('DEL', redis_key)
      else
        try_to_enqueue_job
      end
    end

    private

    delegate :redis, to: 'Rails.application', private: true

    def redis_key
      @redis_key ||= "backup_info:#{token.id}:#{resource}:#{folder_index}"
    end

    def try_to_enqueue_job
      return unless redis.call('SET', redis_key, '', nx: true, ex: INFO_KEY_TTL)

      BackupInfoJob.perform_async(
        token.id,
        resource,
        folder_index || 0,
        redis_key
      )
    end
  end
end
