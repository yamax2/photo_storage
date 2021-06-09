# frozen_string_literal: true

module Rubrics
  # finds photos for the rubric
  #
  # only_with_geo_tags
  # desc_order
  #
  # returns relation
  class PhotosFinder
    def initialize(rubric_id, opts = {})
      @rubric_id = rubric_id
      @only_with_geo_tags = opts.fetch(:only_with_geo_tags, false)

      @columns = opts.fetch(:columns, Photo.arel_table[Arel.star])
      @desc_order = opts.fetch(:desc_order, false)
    end

    def call
      table_name = Photo.quoted_table_name

      asc = @desc_order ? 'DESC' : 'ASC'
      nulls = @desc_order ? 'LAST' : 'FIRST'

      base_scope.order(:rn).select \
        @columns,
        <<~SQL.squish
          ROW_NUMBER() OVER (
            ORDER BY #{table_name}.original_timestamp AT TIME ZONE #{table_name}.tz #{asc} NULLS #{nulls},
                     #{table_name}.id #{asc}
          ) rn
      SQL
    end

    def self.call(rubric_id, opts = {})
      new(rubric_id, opts).call
    end

    private

    def base_scope
      Photo.where(rubric_id: @rubric_id).uploaded.tap do |scope|
        scope.where!(Photo.arel_table[:lat_long].not_eq(nil)) if @only_with_geo_tags
      end
    end
  end
end
