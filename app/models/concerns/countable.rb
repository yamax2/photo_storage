module Countable
  def inc_counter
    return unless persisted?

    RedisClassy.
      redis.
      incr("counters:#{self.class.to_s.underscore}:#{id}").
      to_i
  end
end
