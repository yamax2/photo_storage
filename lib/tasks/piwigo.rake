# frozen_string_literal: true

require 'csv'
require 'open-uri'

# import photos and rubrics from piwigo
namespace :piwigo do
  # rails piwigo:rubrics[ph_categories.csv]
  #
  # CSV example:
  #   id;parent_id;name;comment
  #   "3";;"С режевского тракта в Невьянск (04.04.2015)";"(испытания камеры)"
  #   "5";;"На источники в Туринске (10.05.2015)";"<a href=""https://gpx.mytm.tk/tracks/eaee5c520ba429b0f3e7ac37a0747d1336744960c62899f49719/view"" target=""_blank"">Трек</a>"
  #   "6";;"Озеро Карагуз-Верхний Уфалей-Полевской-Екб (31.05.2015)";
  #   "7";;"Екб-Березники (01.05.2015)";
  #   "64";"56";"Из машины";
  #
  # piwigo mysql query:
  #   select id, id_uppercat parent_id, name, comment from ph_categories order by id_uppercat
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
  #
  # CSV example:
  #   id;rubric_id;original_filename;created_at;name;views;url
  #   "45";"2";"2.jpg";"2015-12-07 13:38:39";"2";"4";"./upload/2015/12/07/20151207133839-049d2228.jpg"
  #   "46";"2";"IMG_4041.JPG";"2015-12-07 13:38:49";"IMG 4041";"11";"./upload/2015/12/07/20151207133849-4ce6cd39.jpg"
  #   "47";"2";"WP_20140622_021.jpg";"2015-12-07 13:38:53";"WP 20140622 021";"11";"./upload/2015/12/07/20151207133853-07da7e23.jpg"
  #   "48";"2";"WP_20140624_009.jpg";"2015-12-07 13:38:56";"WP 20140624 009";"6";"./upload/2015/12/07/20151207133856-c04e26f0.jpg"
  #   "49";"2";"WP_20140626_002.jpg";"2015-12-07 13:38:58";"WP 20140626 002";"5";"./upload/2015/12/07/20151207133858-fd3c9571.jpg"
  #   "70";"3";"20150404_161356.jpg";"2015-12-07 23:00:57";"20150404 161356";"3";"./upload/2015/12/07/20151207230057-07927cc1.jpg"
  #   "71";"3";"20150404_161359.jpg";"2015-12-07 23:00:58";"20150404 161359";"7";"./upload/2015/12/07/20151207230058-de8c2ab0.jpg"
  #   "72";"3";"20150404_161445.jpg";"2015-12-07 23:00:59";"20150404 161445";"4";"./upload/2015/12/07/20151207230059-70d26aa7.jpg"
  #
  # piwigo mysql query:
  #   select img.id, c.category_id rubric_id,
  #          img.file original_filename, img.date_available created_at, img.name,
  #          img.hit views, img.path url
  #     from ph_images img
  #         join ph_image_category c on c.image_id = img.id
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
  #
  # CSV same with photos_upload
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

  # rails piwigo:avatars[ph_avatars.csv]
  #
  # CSV example:
  #   id;avatar_id
  #   "2";"45"
  #   "3";"574"
  #   "4";"185"
  #   "5";"332"
  #
  # piwigo mysql query:
  #   select id, representative_picture_id avatar_id from ph_categories
  task :avatars, %i[filename] => :environment do |_, args|
    CSV.foreach(args.fetch(:filename), col_sep: ';', quote_char: '"', headers: true) do |row|
      rubric = Rubric.find_by_external_info(row['id'])
      next unless rubric

      photo = Photo.find_by(rubric_id: rubric.id, external_info: row['avatar_id'])
      next unless photo

      rubric.main_photo = photo
      rubric.save!

      puts rubric.id
    end
  end
end
