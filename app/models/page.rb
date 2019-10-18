# frozen_string_literal: true

class Page
  attr_reader :rubric
  delegate :rubrics_tree, to: :rubric

  def initialize(rubric_id = nil)
    @rubric = RubricFinder.call(rubric_id).decorate if rubric_id.present?
  end

  # finds photo with prev and next in rubric
  def find_photo_with_next_and_prev(photo_id)
    photos = find_photos(photo_id)

    raise ActiveRecord::RecordNotFound, "photo #{photo_id} not found" if photos.empty?

    Struct.new(:prev, :current, :next).
      new(photos[-1], photos.fetch(0), photos[1])
  end

  def photos
    return @photos if defined?(@photos)
    return @photos = Photo.none unless @rubric

    @photos = photos_scope.decorate
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

  private

  def find_photos(photo_id)
    base_sql = photos_scope.select(
      :id,
      'ROW_NUMBER() OVER (ORDER BY original_timestamp AT TIME ZONE tz NULLS FIRST, id) rn'
    ).to_sql

    Photo.find_by_sql(<<~SQL).map(&:decorate).index_by(&:rn)
      WITH scope AS (
        #{base_sql}
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
         FROM #{Photo.quoted_table_name} photos, ids
        WHERE photos.id = ids.id
          ORDER BY photos.original_timestamp AT TIME ZONE photos.tz NULLS FIRST, photos.id
    SQL
  end

  def photos_scope
    table = Photo.arel_table

    @rubric.
      photos.
      uploaded.
      preload(:yandex_token).
      order(
        PhotosNullsFirstAsc.new(
          Arel::Nodes::InfixOperation.new('AT TIME ZONE', table[:original_timestamp], table[:tz])
        ), table[:id]
      )
  end
end
