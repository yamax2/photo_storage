# frozen_string_literal: true

class Track < ApplicationRecord
  include Storable
  include UploadWorkflow

  MIME_TYPE = 'application/gpx+xml'

  validates :name, presence: true, length: {maximum: 512}
  validates :duration, :distance, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :color, presence: true
  validate :bounds_is_array, if: :storage_filename

  strip_attributes only: %i[name color]

  belongs_to :rubric, inverse_of: :tracks, counter_cache: true
  belongs_to :yandex_token, class_name: 'Yandex::Token',
                            inverse_of: :tracks,
                            optional: true

  def self.available_colors
    @available_colors ||= YAML.load_file(
      Rails.root.join('config/track_colors.yml')
    ).map!(&:downcase)
  end

  # km/h
  def avg_speed
    if duration.zero?
      0.0
    else
      (distance / (duration / 3600)).to_f
    end
  end

  private

  def bounds_is_array
    return if bounds.all?(ActiveRecord::Point) && bounds.size == 2

    errors.add(:bounds, :wrong_value)
  end

  def remove_file
    super

    return if storage_filename.blank?

    ::Tracks::RemoveFileJob.perform_async(
      yandex_token_id,
      storage_filename
    )
  end
end
