# frozen_string_literal: true

module Rubrics
  # finds photos for rubric
  class PhotosFinder
    def initialize(rubric_id, opts = {})
      @rubric_id = rubric_id

      @only_with_geo_tags = opts.fetch(:only_with_geo_tags, false)
      @limit = opts.fetch(:limit, 0)
      @offset = opts.fetch(:offset, 0)
    end

    def call
      scope = photos_scope.tap do |s|
        s.limit!(@limit) if @limit.positive?
        s.offset!(@offset) if @offset.positive?
      end

      scope.preload(:yandex_token).order(:rn)
    end

    def self.call(rubric_id, opts = {})
      new(rubric_id, opts).call
    end

    private

    delegate :quoted_table_name, to: Photo

    def photos_scope
      scope = Photo.where(rubric_id: @rubric_id).uploaded

      scope.where!(Photo.arel_table[:lat_long].not_eq(nil)) if @only_with_geo_tags

      scope.select(
        Photo.arel_table[Arel.star],
        <<~SQL.squish
          ROW_NUMBER() OVER (
            ORDER BY #{quoted_table_name}.original_timestamp AT TIME ZONE #{quoted_table_name}.tz NULLS FIRST,
                     #{quoted_table_name}.id
          ) rn
        SQL
      )
    end
  end
end
