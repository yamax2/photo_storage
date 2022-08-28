# frozen_string_literal: true

module Videos
  class MoveOriginalService
    attr_reader :model

    def initialize(model, temporary_filename)
      @model = model
      @temporary_filename = temporary_filename
    end

    def call
      create_remote_dir

      ::YandexClient::Disk[model.yandex_token.access_token].move(
        @temporary_filename,
        [dir_with_index, model.storage_filename].join('/'),
        overwrite: false
      )
    end

    private

    def dav_client
      @dav_client ||= ::YandexClient::Dav[model.yandex_token.access_token]
    end

    def create_remote_dir
      dav_client.propfind(dir_with_index)
    rescue ::YandexClient::NotFoundError
      dav_client.mkcol(dir_with_index)
    end

    def dir_with_index
      @dir_with_index ||=
        if model.folder_index.nonzero?
          "#{model.yandex_token.other_dir}#{model.folder_index}"
        else
          model.yandex_token.other_dir
        end
    end
  end
end
