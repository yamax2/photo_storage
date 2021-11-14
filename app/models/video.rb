# frozen_string_literal: true

class Video < ApplicationRecord
  include Countable
  include Storable

  ALLOWED_CONTENT_TYPES = %w[
    video/mp4
    video/quicktime
  ].freeze

  belongs_to :rubric, inverse_of: :videos, counter_cache: true
  belongs_to :yandex_token, class_name: 'Yandex::Token', inverse_of: :videos

  validates :name, presence: true, length: {maximum: 512}
  validates :storage_filename, :preview_filename, presence: true, length: {maximum: 512}
  validates :content_type, presence: true, inclusion: ALLOWED_CONTENT_TYPES

  validates :width, :height, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :tz, presence: true, inclusion: Rails.application.config.photo_timezones

  strip_attributes only: %i[name description content_type]
end
