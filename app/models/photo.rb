# frozen_string_literal: true

# photo model, no state machine! no observers!
class Photo < ApplicationRecord
  include Countable
  include Storable

  JPEG_IMAGE = 'image/jpeg'.freeze
  PNG_IMAGE = 'image/png'.freeze

  ALLOWED_CONTENT_TYPES = [
    JPEG_IMAGE,
    PNG_IMAGE
  ].freeze

  belongs_to :rubric, inverse_of: :photos, counter_cache: true
  belongs_to :yandex_token, class_name: 'Yandex::Token',
                            inverse_of: :photos,
                            foreign_key: :yandex_token_id,
                            optional: true

  validates :name, :original_filename, presence: true, length: {maximum: 512}
  validates :width, :height, :size, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :content_type, presence: true, inclusion: ALLOWED_CONTENT_TYPES

  validates :tz, presence: true, inclusion: Rails.application.config.photo_timezones

  strip_attributes only: %i[name description content_type]
  after_commit :remove_from_cart

  before_save { @rubric_changed = rubric_id_changed? if persisted? }
  after_save :change_rubric, on: :update

  private

  def change_rubric
    ::Photos::ChangeMainPhotoService.call!(photo: self) if @rubric_changed
  end

  def read_file_attributes
    super

    self.size = File.size(tmp_local_filename) if size.zero?
  end

  def remove_from_cart
    return unless @rubric_changed || !persisted?

    ::Cart::PhotoService.call!(photo: self, remove: true)
  ensure
    @rubric_changed = nil
  end

  def remove_file
    super

    return unless storage_filename.present?

    ::Photos::RemoveFileJob.perform_async(
      yandex_token_id,
      storage_filename
    )
  end
end
