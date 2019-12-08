# frozen_string_literal: true

class Track < ApplicationRecord
  include Storable

  MIME_TYPE = 'application/gpx+xml'

  validates :name, presence: true, length: {maximum: 512}
  validates :avg_speed, :duration, :distance, presence: true, numericality: {greater_than_or_equal_to: 0}

  strip_attributes only: :name

  belongs_to :rubric, inverse_of: :tracks
  belongs_to :yandex_token, class_name: 'Yandex::Token',
                            foreign_key: :yandex_token_id,
                            inverse_of: :tracks,
                            optional: true
end
