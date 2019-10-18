# frozen_string_literal: true

module Countable
  def inc_counter
    return unless persisted?

    redis = RedisClassy.redis
    key = "counters:#{self.class.to_s.underscore}:#{id}"

    redis.multi do
      redis.persist(key)
      redis.incr(key)
    end.last.to_i
  end
end
