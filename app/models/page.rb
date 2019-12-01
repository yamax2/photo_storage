# frozen_string_literal: true

class Page
  attr_reader :rubric
  delegate :rubrics_tree, to: :rubric

  PageStruct = Struct.new(:prev, :current, :next)

  def initialize(rubric_id = nil, offset: nil, limit: nil, single_rubric_mode: false)
    @offset = offset
    @limit = limit

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

  def photos
    return @photos if defined?(@photos)
    return @photos = Photo.none unless @rubric

    scope =
      if @offset && @limit
        Photo.
          select(Photo.arel_table[Arel.star], 'x.rn').
          where("x.rn > #{@offset}").limit(@limit).
          joins(<<~SQL)
            join (#{photos_scope(true).to_sql}) x on x.id = #{quoted_table_name}.id
          SQL
      else
        photos_scope
      end

    @photos = scope.preload(:yandex_token).order(:rn).decorate
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
        #{photos_scope(true).to_sql}
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

  def photos_scope(only_id = false)
    columns = Array.wrap(only_id ? Photo.arel_table[:id] : Photo.arel_table[Arel.star])
    columns << <<~SQL
      ROW_NUMBER() OVER (
        ORDER BY #{quoted_table_name}.original_timestamp AT TIME ZONE #{quoted_table_name}.tz NULLS FIRST,
                 #{quoted_table_name}.id
      ) rn
    SQL

    @rubric.photos.uploaded.select(*columns)
  end
end
