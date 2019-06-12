class Rubric < ApplicationRecord
  validates :name, presence: true, length: {maximum: 100}

  belongs_to :rubric, optional: true, inverse_of: :rubrics
  has_many :rubrics, dependent: :destroy, inverse_of: :rubric

  strip_attributes only: %i[name description]
end
