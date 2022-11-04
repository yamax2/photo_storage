# frozen_string_literal: true

namespace :migrations do
  desc 'Move files to dirs with folder indexes'
  task move_to_folders: :environment do
    cli = {}
    # with tt as (
    #   select id, size + (props->>'preview_size')::bigint + (props->>'video_preview_size')::bigint size
    #   from photos
    #   where content_type in ('video/mp4', 'video/quicktime') and yandex_token_id = 25 order by id
    # ), volumes as (
    #   select id, size, round(sum(1.0 * size) over(order by id) / (49.5 * 1024*1024*1024)) volume
    #   from tt
    # ), summary as (
    #   select id, volume  from volumes where volume > 0
    # )
    # update photos set
    #   folder_index = summary.volume
    # from summary
    # where summary.id = photos.id
    Photo.
      videos.
      where(Photo.arel_table[:folder_index].gt(0)).
      uploaded.
      joins(:yandex_token).
      includes(:yandex_token).
      order(:yandex_token_id, :id).
      each do |video|
        Rails.logger.info("Processing video: #{video.id}, node id: #{video.yandex_token_id}")

        cli[video.yandex_token_id] ||= ::YandexClient::Dav[video.yandex_token.access_token]

        dest_dir =
          if video.folder_index.nonzero?
            "#{video.yandex_token.other_dir}#{video.folder_index}"
          else
            video.yandex_token.other_dir
          end

        [
          [video.yandex_token.other_dir, video.storage_filename],
          [video.yandex_token.other_dir, video.preview_filename],
          [video.yandex_token.other_dir, video.video_preview_filename]
        ].each do |source_dir, filename|
          source = [source_dir, filename].join('/')
          begin
            cli[video.yandex_token_id].propfind(source)
          rescue YandexClient::NotFoundError
            next
          end

          Rails.logger.info("Moving #{source} (#{video.id}) to #{dest_dir}")

          cli[video.yandex_token_id].move(source, [dest_dir, filename].join('/'))
        end
      end
  end

  desc 'Move photos to dirs with folder indexes'
  task move_photos_to_folders: :environment do
    # with tt as (select id, size, row_number() over (order by id) / 3800 rn from photos
    # where yandex_token_id = 25 and folder_index = 0 and content_type NOT IN ('video/mp4', 'video/quicktime')),
    # source as (select id from tt where rn = 1) , zz as (select id from source) update photos set folder_index = 1
    # where id in (select id from zz) and yandex_token_id = 25 and folder_index = 0
    token = Yandex::Token.find(25)
    cli = ::YandexClient::Dav[token.access_token]

    Photo.images.uploaded.where(folder_index: 1, yandex_token_id: 25).order(:id).each do |photo|
      dest = [
        "#{token.dir}#{photo.folder_index}",
        photo.storage_filename
      ].join('/')

      source = [token.dir, photo.storage_filename].join('/')
      begin
        cli.propfind(source)
      rescue YandexClient::NotFoundError
        next
      end

      remote_path = dest.split('/')
      remote_path.pop
      remote_path.delete_if(&:empty?)

      remote_path_exists =
        begin
          cli.propfind("/#{remote_path.join('/')}")

          true
        rescue ::YandexClient::NotFoundError
          false
        end

      unless remote_path_exists
        Rails.logger.info("Creating #{remote_path.inspect}...")

        remote_path.each_with_object([]) do |dir, path|
          path.push(dir)
          path_to_create = "/#{path.join('/')}"

          begin
            cli.propfind(path_to_create)
          rescue ::YandexClient::NotFoundError
            cli.mkcol(path_to_create)
          end
        end
      end

      Rails.logger.info("Moving #{source} (#{photo.id}) to #{dest}")

      cli.move(source, dest)
    end
  end
end
