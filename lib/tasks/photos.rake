require 'open-uri'
require 'exifr/jpeg'

namespace :photos do
  task repair_dates: :environment do
    table = Photo.arel_table
    dir = Rails.root.join('tmp', 'piwigo_import')

    FileUtils.mkdir_p(dir)

    Photo.
      where.not(original_timestamp: nil).where.not(external_info: nil).
      where(table[:original_timestamp].gt(table[:created_at])).
      order(:id).
      each_instance(with_lock: true) do |photo|
      puts photo.id
      local_file = dir.join("#{SecureRandom.hex(10)}_#{photo.original_filename}")

      File.open(local_file, 'wb') do |file|
        open(photo.decorate.url) { |uri| file.write(uri.read) }
      end

      data = EXIFR::JPEG.new(local_file.to_s)
      photo.original_timestamp = data.date_time || data.date_time_original
      photo.save!

      FileUtils.rm_f(local_file)
    end
  end
end
