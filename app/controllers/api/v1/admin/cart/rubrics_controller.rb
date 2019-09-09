module Api
  module V1
    module Admin
      module Cart
        # rubrics cart formatted for jstree
        class RubricsController < ::ActionController::API
          helper_method :selected_rubric_ids

          def index
            @rubrics = Rubric.
              where(id: selected_rubric_ids.keys, rubric_id: params[:id]).
              default_order.
              decorate
          end

          private

          delegate :redis, to: RedisClassy

          def selected_rubric_ids
            @selected_rubric_ids ||= redis.
              scan_each(match: 'cart:photos:*', count: 1_000).
              each_with_object({}) { |key, memo| memo[key.gsub(/[^\d]+/, '').to_i] = redis.scard(key) }
          end
        end
      end
    end
  end
end
