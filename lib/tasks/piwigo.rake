require 'csv'
require 'open-uri'

namespace :piwigo do
  task :rubrics, [:filename] => :environment do |_, args|
    Rubric.transaction do
      CSV.foreach(args.fetch(:filename), col_sep: ';', quote_char: '"', headers: true) do |row|
        rubric = Rubric.new(name: row['name'], description: row['comment'], external_info: row['id'])

        rubric.rubric = Rubric.find_by_external_info!(row['parent_id']) if row['parent_id'].present?
        rubric.save!

        puts "#{rubric.id}: #{rubric.name}"
      end
    end
  end

  # rails piwigo:photos_upload[ph_photos.csv,101,http://10.0.0.2:8082]
  task :photos_upload, %i[filename external_rubric_id host] => :environment do |_, args|
    rubric = Rubric.find_by_external_info!(args.fetch(:external_rubric_id))
    piwigo_host = args.fetch(:host)

    dir = Rails.root.join('tmp', 'piwigo_import')
    FileUtils.mkdir_p(dir)

    CSV.foreach(args.fetch(:filename), col_sep: ';', quote_char: '"', headers: true) do |row|
      next unless row['rubric_id'] == rubric.external_info
      next if Photo.where(external_info: row['id']).exists?

      url = "#{piwigo_host}/#{row['url'].sub(%r{^\./}, '')}"
      local_file = dir.join(row['original_filename'])

      File.open(local_file, 'wb') do |file|
        open(url) { |uri| file.write(uri.read) }
      end

      uploaded_io = ActionDispatch::Http::UploadedFile.new(
        filename: row['original_filename'],
        type: Rack::Mime.mime_type(File.extname(row['original_filename'])),
        tempfile: File.open(local_file)
      )

      context = Photos::EnqueueProcessService.call!(
        uploaded_io: uploaded_io,
        rubric_id: rubric.id,
        external_info: row['id']
      )

      puts context.photo.id

      FileUtils.rm_f(local_file)
    end
  end

  # rails piwigo:photos_attrs[ph_photos.csv]
  task :photos_attrs, %i[filename] => :environment do |_, args|
    redis_key = 'piwigo:loaded'

    CSV.foreach(args.fetch(:filename), col_sep: ';', quote_char: '"', headers: true) do |row|
      photo = Photo.find_by_external_info(row['id'])

      next if photo.nil? || RedisClassy.redis.sismember(redis_key, photo.id)

      puts "rubric #{photo.rubric_id}, photo #{photo.id}"

      photo.views += row['views'].to_i
      photo.name = row['name']
      photo.created_at = Time.strptime(row['created_at'], '%Y-%m-%d %T')

      photo.save!

      RedisClassy.redis.sadd(redis_key, photo.id)
    end
  end
end
