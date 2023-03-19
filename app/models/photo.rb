# frozen_string_literal: true

# photo model, no state machine! no observers!
# FIXME: add sti
class Photo < ApplicationRecord
  include Countable
  include Storable
  include UploadWorkflow

  JPEG_CONTENT_TYPES = %w[image/jpeg image/jpg image/jpe].freeze
  VIDEO_CONTENT_TYPES = %w[video/mp4 video/quicktime].freeze
  IMAGE_CONTENT_TYPES = %w[image/png].concat(JPEG_CONTENT_TYPES).freeze

  ALLOWED_CONTENT_TYPES = (IMAGE_CONTENT_TYPES + VIDEO_CONTENT_TYPES).freeze
  ALLOWED_EFFECTS = [
    /^scaleX\((-?)\d+\)$/,
    /^scaleY\((-?)\d+\)$/
  ].freeze

  belongs_to :rubric, inverse_of: :photos, counter_cache: true
  belongs_to :yandex_token, class_name: 'Yandex::Token',
                            inverse_of: :photos,
                            optional: true

  store_accessor :props,
                 :rotated, :effects, :external_info, :hide_on_map, :duration,
                 :preview_filename, :preview_size, :preview_md5, :preview_sha256,
                 :video_preview_filename, :video_preview_size, :video_preview_md5, :video_preview_sha256

  validates :name, presence: true, length: {maximum: 512}
  validates :width, :height, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :content_type, presence: true, inclusion: ALLOWED_CONTENT_TYPES
  validates :tz, presence: true, inclusion: Rails.application.config.photo_timezones

  validates :rotated, numericality: {only_integer: true}, allow_blank: true, inclusion: [1, 2, 3] # 90, 180, 270
  validate :validate_effects

  # video attrs
  validates :local_filename, :rotated, :effects, absence: true, if: :video?
  validates :storage_filename, presence: true, if: :video?
  validates :preview_filename, :video_preview_filename, presence: true, length: {maximum: 512}, if: :video?
  validates :preview_size, :video_preview_size,
            presence: true, numericality: {only_integer: true, greater_than: 0}, if: :video?
  validates :preview_md5, :video_preview_md5, presence: true, length: {is: 32}, if: :video?
  validates :preview_sha256, :video_preview_sha256, presence: true, length: {is: 64}, if: :video?
  validates :duration, :preview_filename, :preview_size, :preview_md5, :preview_sha256,
            :video_preview_filename, :video_preview_size, :video_preview_md5, :video_preview_sha256,
            absence: true, unless: :video?

  strip_attributes only: %i[name description content_type]

  before_save do
    props.compact!

    @rubric_changed = rubric_id_changed? if persisted?
  end

  after_update :change_rubric
  after_commit :remove_from_cart

  scope :images, -> { where.not(content_type: VIDEO_CONTENT_TYPES) }
  scope :videos, -> { where(content_type: VIDEO_CONTENT_TYPES) }

  def jpeg?
    JPEG_CONTENT_TYPES.include?(content_type)
  end

  def video?
    VIDEO_CONTENT_TYPES.include?(content_type)
  end

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

  # if this method fails after commit, we have to check the revise result
  def remove_file
    super

    if video?
      enqueue_remove_job(yandex_token.other_dir, [storage_filename, preview_filename, video_preview_filename])
    elsif storage_filename.present?
      enqueue_remove_job(yandex_token.dir, storage_filename)
    end
  end

  def validate_effects
    return if effects.nil?

    valid = effects.is_a?(Array) && effects.all? { |value| ALLOWED_EFFECTS.any? { |regex| value =~ regex } }

    errors.add(:effects, :invalid) unless valid
  end

  def enqueue_remove_job(dir, filenames)
    args = Array.wrap(filenames).filter_map do |filename|
      next if filename.blank?

      dir_with_index = dir
      dir_with_index = "#{dir}#{folder_index}" if folder_index.nonzero?

      [
        yandex_token_id,
        [dir_with_index, filename].join('/')
      ]
    end

    ::Yandex::RemoveFileJob.perform_bulk(args)
  end
end
