# frozen_string_literal: true

module Api
  module V1
    module Admin
      module Cart
        # rubrics cart formatted for jstree
        class RubricsController < AdminController
          helper_method :selected_rubric_ids, :children?

          def index
            @rubrics = Rubric.
              where(id: selected_rubric_ids.keys, rubric_id: params[:id]).
              default_order
          end

          private

          delegate :redis, to: 'Rails.application', private: true

          # FIXME: wft?
          def children?(rubric)
            rubric.rubrics_count.positive? &&
              rubric.rubrics.with_objects.pluck(:id).intersect?(selected_rubric_ids.keys)
          end

          def selected_rubric_ids
            # FIXME: wft????
            @selected_rubric_ids ||= redis.
              scan('MATCH', 'cart:photos:*', count: 1_000).
              each_with_object({}) { |key, memo| memo[key.gsub(/[^\d]+/, '').to_i] = redis.call('SCARD', key) }
          end
        end
      end
    end
  end
end
