# frozen_string_literal: true

module Videos
  class MoveOriginalJob
    include Sidekiq::Worker

    def perform(id, temporary_filename)
      video = Photo.find(id)
      node = video.yandex_token

      ::YandexClient::Disk[node.access_token].move(
        temporary_filename,
        [node.other_dir, video.storage_filename].join('/'),
        overwrite: false
      )
    end
  end
end
