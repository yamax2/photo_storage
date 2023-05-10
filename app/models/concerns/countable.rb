# frozen_string_literal: true

module Countable
  extend ActiveSupport::Concern

  def inc_counter
    return unless persisted?

    key = "counters:#{self.class.to_s.underscore}:#{id}"

    Rails.application.redis.multi do |redis|
      redis.call('PERSIST', key)
      redis.call('INCR', key)
    end.last.to_i
  end
end
