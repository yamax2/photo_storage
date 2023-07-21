# frozen_string_literal: true

module Rubrics
  class CurrentPhotoFinder
    PageStruct = Struct.new(:prev, :current, :next)

    def initialize(rubric_id, photo_id)
      @rubric_id = rubric_id
      @photo_id = photo_id
    end

    def call
      photos = find_photos

      raise ActiveRecord::RecordNotFound, "photo #{@photo_id} not found" if photos.empty?

      PageStruct.new(photos[-1], photos.fetch(0), photos[1])
    end

    def self.call(rubric_id, photo_id)
      new(rubric_id, photo_id).call
    end

    private

    def find_photos # rubocop:disable Metrics/MethodLength
      Photo.find_by_sql(<<~SQL.squish).index_by(&:rn)
        WITH scope AS (
          #{PhotosFinder.call(@rubric_id).to_sql}
        ), current_photo AS (
          SELECT id, rn FROM scope WHERE id = #{@photo_id}
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
      SQL
    end
  end
end
