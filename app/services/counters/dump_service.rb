module Counters
  class DumpService
    include ::Interactor

    delegate :model_klass, to: :context

    def call
      # batches?
      redis.
        scan_each(match: key_for('*')).
        each do |key|
        model = model_klass.where(id: key.gsub(/[^\d]+/, '').to_i).first
        dump_counter(model) if model
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
