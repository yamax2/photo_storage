class Rubric < ApplicationRecord
  belongs_to :rubric, optional: true, inverse_of: :rubrics, counter_cache: true
  has_many :rubrics, dependent: :destroy, inverse_of: :rubric
  has_many :photos, dependent: :destroy, inverse_of: :rubric

  validates :name, presence: true, length: {maximum: 100}

  strip_attributes only: %i[name description]

  scope :with_photos, -> { where('photos_count > 0') }
end
