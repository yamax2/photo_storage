# frozen_string_literal: true

class Rubric < ApplicationRecord
  belongs_to :rubric, optional: true, inverse_of: :rubrics, counter_cache: true
  belongs_to :main_photo, optional: true, class_name: 'Photo'

  has_many :rubrics, dependent: :destroy, inverse_of: :rubric
  has_many :photos, dependent: :destroy, inverse_of: :rubric
  has_many :tracks, dependent: :destroy, inverse_of: :rubric

  validates :name, presence: true, length: {maximum: 100}

  strip_attributes only: %i[name description]

  scope(:with_objects, lambda do
    where(<<~SQL.squish)
      rubrics.id IN (
        WITH RECURSIVE tt AS (
        SELECT id, rubric_id FROM #{quoted_table_name}
        WHERE photos_count + tracks_count > 0
        UNION ALL
        SELECT rubrics.id, rubrics.rubric_id
        FROM #{quoted_table_name} rubrics, tt WHERE rubrics.id = tt.rubric_id)
        SELECT id FROM tt
      )
    SQL
  end)

  scope :default_order, -> { order(arel_table[:ord].asc.nulls_first, arel_table[:id].desc) }
  scope(:by_first_object, lambda do
    joins(<<~SQL.squish).order('sort.rn')
      JOIN (
        WITH ords as (
          SELECT rubrics.id,
                 (
                    SELECT MIN(original_timestamp) FROM #{Photo.quoted_table_name}
                      WHERE rubric_id = rubrics.id AND original_timestamp IS NOT NULL
                 ) photo_time
          FROM #{quoted_table_name} rubrics
        )
        SELECT id,
               ROW_NUMBER() OVER (ORDER BY photo_time DESC NULLS LAST, id DESC) rn
          FROM ords
      ) sort ON sort.id = #{quoted_table_name}.id
    SQL
  end)

  def rubrics_tree
    current_rubric = self
    rubrics = []

    loop do
      rubrics << current_rubric
      current_rubric = current_rubric.rubric

      break if current_rubric.blank?
    end

    rubrics
  end
end
