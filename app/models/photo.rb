class Photo < ApplicationRecord
  JPEG_IMAGE = 'image/jpeg'.freeze
  PNG_IMAGE = 'image/png'.freeze

  ALLOWED_CONTENT_TYPES = [
    JPEG_IMAGE,
    PNG_IMAGE
  ].freeze

  belongs_to :rubric, inverse_of: :photos
  belongs_to :yandex_token, class_name: 'Yandex::Token',
                            inverse_of: :photos,
                            foreign_key: :yandex_token_id,
                            optional: true

  validates :name, :original_filename, presence: true, length: {maximum: 512}
  validates :width, :height, :size, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :content_type, presence: true, inclusion: ALLOWED_CONTENT_TYPES
  validate :upload_status

  strip_attributes only: %i[name description content_type]

  before_validation { self.original_timestamp ||= Time.current }

  scope :uploaded, -> { where.not(storage_filename: nil) }
  scope :pending, -> { where.not(local_filename: nil) }

  private

  def upload_status
    errors.add(:local_filename, :wrong_value) if storage_filename.present? && local_filename.present?
  end
end
