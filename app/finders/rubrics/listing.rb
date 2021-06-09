# frozen_string_literal: true

module Rubrics
  class Listing
    include Enumerable

    COLUMNS = (::Listing::Item::COLUMNS - %w[yandex_token model_type photos_count rubrics_count]).freeze
    COLUMNS_FOR_RUBRIC = (COLUMNS - %w[id name rubric_id]).freeze
    private_constant :COLUMNS, :COLUMNS_FOR_RUBRIC

    def initialize(rubric_id = nil, opts = {})
      @rubric_id = rubric_id
      @only_with_geo_tags = opts.fetch(:only_with_geo_tags, false)

      raise 'only_with_geo_tags allowed only for rubric' if @only_with_geo_tags && @rubric_id.nil?

      @limit = opts.fetch(:limit, 0)
      @offset = opts.fetch(:offset, 0)
      @desc_order = opts.fetch(:desc_order, false)
    end

    def each
      return to_enum unless block_given?

      scope.each do |model|
        attrs = model.attributes
        attrs[:yandex_token] = model.yandex_token

        yield ::Listing::Item.new(attrs)
      end

      self
    end

    private

    def scope
      Photo.
        select(*COLUMNS, :photos_count, :rubrics_count, :model_type).
        from(base_scope.as('query')).
        preload(:yandex_token).
        reorder(:model_index, :rn).
        readonly.tap do |scope|
        scope.limit!(@limit) if @limit.positive?
        scope.offset!(@offset) if @offset.positive?
      end
    end

    def base_scope
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
        :rubric_id,
        "ROW_NUMBER() OVER (ORDER BY #{scope.order_values.map(&:to_sql).join(',')}) rn",
        :photos_count, :rubrics_count, '0 model_index',
        "#{Rubric.connection.quote('Rubric')} model_type"
      )
    end

    def photos_scope
      photos = Photo.arel_table

      PhotosFinder.call(
        @rubric_id,
        columns: COLUMNS.map { |attr| photos[attr] },
        only_with_geo_tags: @only_with_geo_tags,
        desc_order: @desc_order
      ).select(
        '0 photos_count', '0 rubrics_count', '1 model_index',
        "#{Photo.connection.quote('Photo')} model_type"
      )
    end
  end
end
