class Rubric < ApplicationRecord
  belongs_to :rubric, optional: true, inverse_of: :rubrics, counter_cache: true
  belongs_to :main_photo, optional: true, class_name: 'Photo'

  has_many :rubrics, dependent: :destroy, inverse_of: :rubric
  has_many :photos, dependent: :destroy, inverse_of: :rubric

  validates :name, presence: true, length: {maximum: 100}

  strip_attributes only: %i[name description]

  scope :with_photos, -> {
    where(<<~SQL)
      rubrics.id in (
        WITH RECURSIVE tt AS (
        SELECT id, rubric_id FROM #{Rubric.quoted_table_name} WHERE photos_count > 0
        UNION ALL
        SELECT rubrics.id, rubrics.rubric_id
        FROM #{Rubric.quoted_table_name} rubrics, tt WHERE rubrics.id = tt.rubric_id)
        SELECT id FROM tt
      )
    SQL
  }
end
