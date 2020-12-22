# frozen_string_literal: true

# photo model, no state machine! no observers!
class Photo < ApplicationRecord
  include Countable
  include Storable

  JPEG_IMAGE = 'image/jpeg'
  PNG_IMAGE = 'image/png'

  ALLOWED_CONTENT_TYPES = [
    JPEG_IMAGE,
    PNG_IMAGE
  ].freeze

  ALLOWED_EFFECTS = [
    /^scaleX\((-?)\d+\)$/,
    /^scaleY\((-?)\d+\)$/
  ].freeze

  belongs_to :rubric, inverse_of: :photos, counter_cache: true
  belongs_to :yandex_token, class_name: 'Yandex::Token',
                            inverse_of: :photos,
                            optional: true

  store_accessor :props, :rotated, :external_info, :effects

  validates :name, presence: true, length: {maximum: 512}
  validates :width, :height, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :content_type, presence: true, inclusion: ALLOWED_CONTENT_TYPES
  validates :tz, presence: true, inclusion: Rails.application.config.photo_timezones

  validates :rotated, numericality: {only_integer: true}, allow_blank: true, inclusion: [1, 2, 3] # 90, 180, 270
  validate :validate_effects

  strip_attributes only: %i[name description content_type]

  before_save { @rubric_changed = rubric_id_changed? if persisted? }
  after_update :change_rubric
  after_commit :remove_from_cart

  private

  def change_rubric
    ::Photos::ChangeMainPhoto.call!(photo: self) if @rubric_changed
  end

  def remove_from_cart
    return unless @rubric_changed || !persisted?

    ::Cart::PhotoService.call!(photo: self, remove: true)
  ensure
    @rubric_changed = nil
  end

  def remove_file
    super

    return if storage_filename.blank?

    ::Photos::RemoveFileJob.perform_async(
      yandex_token_id,
      storage_filename
    )
  end

  def validate_effects
    return if effects.nil?

    valid = effects.is_a?(Array) && effects.all? { |value| Photo::ALLOWED_EFFECTS.any? { |regex| value =~ regex } }

    errors.add(:effects, :invalid) unless valid
  end
end
