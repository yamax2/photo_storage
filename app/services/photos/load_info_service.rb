require 'exifr/jpeg'

module Photos
  class LoadInfoService
    include ::Interactor

    delegate :photo, to: :context

    def call
      return unless valid?

      photo.exif = {model: exif_data.model, make: exif_data.make}

      load_gps_attrs
      load_photo_attrs

      photo.save!
    end

    private

    def exif_data
      @exif_data ||= EXIFR::JPEG.new(photo.tmp_local_filename.to_s)
    end

    def load_gps_attrs
      return unless exif_data.gps.present?

      photo.lat_long = [exif_data.gps.latitude, exif_data.gps.longitude]
    end

    def load_photo_attrs
      photo.original_timestamp = exif_data.date_time

      photo.width = exif_data.width
      photo.height = exif_data.height
    end

    def valid?
      photo.content_type == Photo::JPEG_IMAGE && \
        photo.exif.nil? && \
        exif_data.exif? && \
        photo.local_file?
    end
  end
end
