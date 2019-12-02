class Track < ApplicationRecord
  validates :name, presence: true, length: {maximum: 512}

  belongs_to :rubric, inverse_of: :tracks
  has_many :track_items, dependent: :destroy, inverse_of: :track

  strip_attributes only: :name
end
