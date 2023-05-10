# frozen_string_literal: true

module RedisHelper
  def redis
    Thread.current[:redis] ||= redis_config.new_client
  end

  def redlock
    Thread.current[:redlock] ||= Redlock::Client.new(
      [redis],
      {
        retry_count: 10,
        retry_delay: ->(attempt_number) { 200 * attempt_number } # ms
      }
    )
  end

  def redis_config
    @redis_config ||= RedisClient.config(**Rails.application.config.redis)
  end
end
