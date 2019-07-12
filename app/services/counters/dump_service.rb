module Counters
  class DumpService
    include ::Interactor

    delegate :model_klass, to: :context

    def call
      # batches?
      redis.scan_each(match: key_for('*')).each do |key|
        id = key.gsub(/[^\d]+/, '').to_i

        if (model = model_klass.where(id: id).first).present?
          dump_counter(model)
        else
          redis.del(key_for(id))
        end
      end
    end

    private

    delegate :redis, to: RedisClassy

    def dump_counter(model)
      key = key_for(model.id)

      value = redis.multi do
        redis.get(key)
        redis.del(key)
      end.first

      model.update_column(:views, model.views + value.to_i) if value.present?
    end

    def key_for(id)
      "counters:#{model_klass.to_s.underscore}:#{id}"
    end
  end
end
