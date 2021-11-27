# frozen_string_literal: true

require 'exifr/jpeg'
require 'image_size'

module Photos
  class LoadInfoService
    include ::Interactor

    delegate :photo, to: :context

    def call
      return unless photo.local_file?

      if exif?
        photo.exif = {model: exif_data.model, make: exif_data.make}

        load_gps_attrs
        load_photo_exif_attrs
      else
        load_file_attrs
      end

      photo.save!
    end

    private

    def exif?
      photo.jpeg? && \
        photo.exif.nil? && \
        exif_data.exif? && \
        (exif_data.model.present? || exif_data.make.present?)
    end

    def exif_data
      @exif_data ||= EXIFR::JPEG.new(photo.tmp_local_filename.to_s)
    end

    def gps_attrs_present?
      exif_data.gps.present? && \
        !(exif_data.gps.latitude.zero? && exif_data.gps.longitude.zero?)
    end

    def load_file_attrs
      info = ImageSize.path(photo.tmp_local_filename.to_s)

      photo.assign_attributes(width: info.w, height: info.h)
    end

    def load_gps_attrs
      return unless gps_attrs_present?

      photo.lat_long = [exif_data.gps.latitude, exif_data.gps.longitude]
    end

    def load_photo_exif_attrs
      photo.assign_attributes(photo_size)
      photo.original_timestamp = exif_data.date_time_original || exif_data.date_time
    end

    def photo_size
      case exif_data.orientation&.to_sym
      when :RightTop, :LeftTop, :RightBottom, :LeftBottom
        {height: exif_data.width, width: exif_data.height}
      else
        {width: exif_data.width, height: exif_data.height}
      end
    end
  end
end
