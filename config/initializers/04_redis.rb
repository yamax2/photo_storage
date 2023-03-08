# frozen_string_literal: true

redis = Redis.new(Rails.application.config.redis)
RedisClassy.redis = redis
