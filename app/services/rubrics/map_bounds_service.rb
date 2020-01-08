# frozen_string_literal: true

module Rubrics
  class MapBoundsService
    include ::Interactor

    delegate :rubric_id, to: :context

    def call
      context.bounds = ActiveRecord::Base.connection.execute(<<~SQL).first.symbolize_keys!
        SELECT MIN(lat) min_lat, MIN(long) min_long, MAX(lat) max_lat, MAX(long) max_long
          FROM (#{bounds_query}) info
      SQL

      context.bounds = nil if context.bounds.values.all?(&:blank?)
    end

    private

    def bounds_query
      [
        Photo.where(rubric_id: rubric_id).uploaded.where.not(lat_long: nil).select('lat_long[0] lat, lat_long[1] long'),
        Track.where(rubric_id: rubric_id).uploaded.joins(', unnest(bounds) points').select('points[0], points[1]')
      ].map(&:to_sql).join(' UNION ALL ')
    end
  end
end
