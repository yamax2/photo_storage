# frozen_string_literal: true

module Counters
  class DumpService
    include ::Interactor

    BATCH_SIZE = 100
    LOADED_COUNTER_TTL = 1.hour

    delegate :model_klass, to: :context

    def call
      redis.scan_each(match: key_for('*'), count: BATCH_SIZE) do |key|
        id = key.gsub(/[^\d]+/, '').to_i

        if (model = model_klass.find_by(id:)).present?
          dump_counter(model)
        else
          redis.expire(key_for(id), LOADED_COUNTER_TTL)
        end
      end
    end

    private

    delegate :redis, to: RedisClassy

    def dump_counter(model)
      key = key_for(model.id)

      value = redis.multi do |r|
        r.getset(key, 0)
        r.expire(key, LOADED_COUNTER_TTL)
      end.first

      # when db fails?
      model.update_column(:views, model.views + value.to_i) if value.present?
    end

    def key_for(id)
      "counters:#{model_klass.to_s.underscore}:#{id}"
    end
  end
end
