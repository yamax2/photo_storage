# frozen_string_literal: true

module RSpecHelpers
  module Sidekiq
    def enqueued_jobs(queue = 'default', klass: nil)
      jobs = ::Sidekiq.
        redis { |redis| redis.lrange("queue:#{queue}", 0, -1) }.
        map! { |j| JSON.parse(j) }

      jobs.select! { |j| j['class'] == klass.to_s } if klass

      jobs
    end

    def scheduled_jobs
      jobs = ::Sidekiq.
        redis { |redis| redis.zrange('schedule', 0, -1) }.
        map! { |j| JSON.parse(j) }.
        group_by { |j| j.delete('queue') }

      {'default' => []}.merge!(jobs)
    end
  end
end
