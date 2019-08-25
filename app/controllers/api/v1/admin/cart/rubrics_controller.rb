module Admin
  module Cart
    # rubrics cart formatted for jstree
    class RubricsController < ::ActionController::API
      def index
        @ids = redis.
          scan_each(match: 'cart:photos:*', count: 1_000).
          each_with_object({}) { |key, memo| memo[key.gsub(/[^\d]+/, '').to_i] = redis.scard(key) }

        @rubrics = Rubric.where(id: @ids.keys).default_order
      end

      delegate :redis, to: RedisClassy
    end
  end
end
