# frozen_string_literal: true

# FIXME: temporary
Redis.silence_deprecations = true

redis = Redis.new(Rails.application.config.redis)
RedisClassy.redis = redis
