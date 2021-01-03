# frozen_string_literal: true

module Rubrics
  class ListingFinder
    COLUMNS = %i[
      id
      name
      yandex_token_id
      storage_filename
      content_type
      width
      height
      lat_long
      props
      rubric_id
    ].freeze
    COLUMNS_FOR_RUBRIC = (COLUMNS - %i[id name rubric_id]).freeze
    private_constant :COLUMNS, :COLUMNS_FOR_RUBRIC

    def initialize(rubric_id = nil, opts = {})
      @rubric_id = rubric_id
      @only_with_geo_tags = opts.fetch(:only_with_geo_tags, false)

      raise 'only_with_geo_tags allowed only for rubric' if @only_with_geo_tags && @rubric_id.nil?

      @limit = opts.fetch(:limit, 0)
      @offset = opts.fetch(:offset, 0)
    end

    def self.call(rubric_id = nil, opts = {})
      new(rubric_id, opts).call
    end

    def call
      Photo.select(*COLUMNS, :model_type).from(
        scope.as('query')
      ).reorder(:model_index, :rn).tap do |scope|
        scope.limit!(@limit) if @limit.positive?
        scope.offset!(@offset) if @offset.positive?
      end
    end

    private

    def scope
      if @only_with_geo_tags
        photos_scope.arel
      elsif @rubric_id.present?
        Arel::Nodes::UnionAll.new(
          photos_scope.arel,
          rubrics_scope.arel
        )
      else
        rubrics_scope.arel
      end
    end

    def rubrics_scope
      photos = Photo.arel_table
      scope = Rubric.where(rubric_id: @rubric_id).with_photos.left_joins(:main_photo).default_order

      scope.select(
        :id, :name,
        *COLUMNS_FOR_RUBRIC.map { |attr| photos[attr] },
        'null rubric_id',
        "ROW_NUMBER() OVER (ORDER BY #{scope.order_values.map(&:to_sql).join(',')}) rn",
        '0 model_index',
        "#{Rubric.connection.quote('Rubric')} model_type"
      )
    end

    def photos_scope
      photos = Photo.arel_table

      PhotosFinder.call(
        @rubric_id,
        columns: COLUMNS.map { |attr| photos[attr] },
        only_with_geo_tags: @only_with_geo_tags
      ).select(
        '1 model_index',
        "#{Photo.connection.quote('Photo')} model_type"
      )
    end
  end
end
