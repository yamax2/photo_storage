# frozen_string_literal: true

# decorator
class Page
  attr_reader :rubric
  delegate :rubrics_tree, to: :rubric

  PageStruct = Struct.new(:prev, :current, :next)

  def initialize(rubric_id = nil, single_rubric_mode: false)
    return unless rubric_id

    rubric =
      if single_rubric_mode
        Rubric.find(rubric_id)
      else
        RubricFinder.call(rubric_id)
      end

    @rubric = rubric.decorate
  end

  # finds photo with prev and next in rubric
  def find_photo_with_next_and_prev(photo_id)
    photos = find_photos(photo_id)

    raise ActiveRecord::RecordNotFound, "photo #{photo_id} not found" if photos.empty?

    PageStruct.new(photos[-1], photos.fetch(0), photos[1])
  end

  # pagination:
  #   * limit
  #   * offset
  #
  # filters:
  #   * only_with_geo_tags
  def photos(options = {})
    scope =
      if @rubric
        limited_scope(
          limit: options[:limit], offset: options.fetch(:offset, 0),
          only_with_geo_tags: options.fetch(:only_with_geo_tags, false)
        ).preload(:yandex_token).order(:rn)
      else
        Photo.none
      end

    scope.decorate
  end

  def rubrics
    return @rubrics if defined?(@rubrics)

    rubrics = @rubric&.rubrics || Rubric.where(rubric_id: nil)

    @rubrics = rubrics.
      with_photos.
      preload(main_photo: :yandex_token).
      default_order.
      decorate
  end

  def with_rubrics?
    @rubric.nil? || @rubric.rubrics_count.positive? && rubrics.any?
  end

  private

  delegate :quoted_table_name, to: Photo

  def find_photos(photo_id)
    Photo.find_by_sql(<<~SQL).map(&:decorate).index_by(&:rn)
      WITH scope AS (
        #{photos_scope(only_id: true).to_sql}
      ), current_photo AS (
        SELECT id, rn FROM scope WHERE id = #{photo_id}
      ), ids AS (
         SELECT scope.id,
                scope.rn - current_photo.rn rn,
                scope.rn pos
           FROM scope, current_photo
         WHERE scope.id = current_photo.id OR
               scope.rn in (current_photo.rn - 1, current_photo.rn + 1)
      )
      SELECT photos.*, ids.rn, ids.pos
         FROM #{quoted_table_name} photos, ids
        WHERE photos.id = ids.id
    SQL
  end

  def limited_scope(limit:, offset:, only_with_geo_tags: false)
    if limit&.positive? && offset
      Photo.select(Photo.arel_table[Arel.star], 'x.rn').
        where("x.rn > #{offset}").limit(limit).
        joins(<<~SQL)
          join (
            #{photos_scope(only_id: true, only_with_geo_tags: only_with_geo_tags).to_sql}
          ) x on x.id = #{quoted_table_name}.id
        SQL
    else
      photos_scope(only_with_geo_tags: only_with_geo_tags)
    end
  end

  def photos_scope(only_id: false, only_with_geo_tags: false)
    table = Photo.arel_table

    columns = [only_id ? table[:id] : table[Arel.star]]
    columns << <<~SQL
      ROW_NUMBER() OVER (
        ORDER BY #{quoted_table_name}.original_timestamp AT TIME ZONE #{quoted_table_name}.tz NULLS FIRST,
                 #{quoted_table_name}.id
      ) rn
    SQL

    scope = @rubric.photos.uploaded
    scope.where!(table[:lat_long].not_eq(nil)) if only_with_geo_tags

    scope.select(*columns)
  end
end
