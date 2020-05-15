# frozen_string_literal: true

module Countable
  def inc_counter
    return unless persisted?

    key = "counters:#{self.class.to_s.underscore}:#{id}"

    RedisClassy.redis.multi do |redis|
      redis.persist(key)
      redis.incr(key)
    end.last.to_i
  end
end
