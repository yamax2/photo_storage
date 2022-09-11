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
end
