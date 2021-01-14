# frozen_string_literal: true

Redis.current = Redis.new(Rails.application.config.redis)
RedisClassy.redis = Redis.current
