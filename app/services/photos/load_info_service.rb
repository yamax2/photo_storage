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
        load_photo_attrs
      end

      photo.save!
    end

    private

    def exif?
      photo.content_type == Photo::JPEG_IMAGE && \
        photo.exif.nil? && \
        exif_data.exif?
    end

    def exif_data
      @exif_data ||= EXIFR::JPEG.new(photo.tmp_local_filename.to_s)
    end

    def load_gps_attrs
      return unless exif_data.gps.present?

      photo.lat_long = [exif_data.gps.latitude, exif_data.gps.longitude]
    end

    def load_photo_attrs
      info = ImageSize.path(photo.tmp_local_filename.to_s)

      photo.assign_attributes(width: info.w, height: info.h)
    end

    def load_photo_exif_attrs
      photo.assign_attributes(
        original_timestamp: exif_data.date_time,
        width: exif_data.width,
        height: exif_data.height
      )
    end
  end
end
