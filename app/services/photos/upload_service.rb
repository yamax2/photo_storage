# frozen_string_literal: true

module Photos
  class UploadService
    include ::Interactor

    delegate :photo, :storage_filename, :folder_index, to: :context, private: true

    def call
      return if photo.storage_filename.present?

      validate_upload

      context.storage_filename ||= StorageFilenameGenerator.call(photo)
      context.folder_index = token_for_upload.photos_folder_index.to_i

      create_remote_dirs
      upload_file
      update_photo
    end

    private

    def client
      @client ||= ::YandexClient::Dav[token_for_upload.access_token]
    end

    def create_remote_dir(path)
      Retry.for(:yandex) do
        client.propfind(path)
      rescue ::YandexClient::NotFoundError
        client.mkcol(path)
      end
    end

    def create_remote_dirs
      return if remote_path_exists?

      Rails.application.redlock.lock!(
        "yandex:dirs:#{token_for_upload.id}:#{remote_path.join(':')}", 1.minute.in_milliseconds
      ) do
        remote_path.each_with_object([]) do |dir, path|
          path.push(dir)

          create_remote_dir("/#{path.join('/')}")
        end
      end
    end

    def local_file
      @local_file ||= photo.tmp_local_filename
    end

    def remote_path
      return @remote_path if defined?(@remote_path)

      @remote_path = dir_with_index.split('/').concat(storage_filename.split('/'))

      @remote_path.pop
      @remote_path.delete_if(&:empty?)

      @remote_path
    end

    def remote_path_exists?
      Retry.for(:yandex) do
        client.propfind("/#{remote_path.join('/')}")

        true
      rescue ::YandexClient::NotFoundError
        false
      end
    end

    def token_for_upload
      @token_for_upload ||= Yandex::Token.where(
        id: Yandex::TokenForUploadService.call!(resource_size: photo.size).token_id
      ).first
    end

    def upload_file
      Retry.for(:yandex) do
        client.put \
          local_file,
          [dir_with_index, storage_filename].join('/'),
          size: photo.size,
          etag: photo.md5,
          sha256: photo.sha256
      end
    end

    def validate_upload
      context.fail!(message: "#{photo.id} is not an image") if photo.video?
      context.fail!(message: 'local file not found') unless photo.local_file?
      context.fail!(message: 'active token not found') if token_for_upload.blank?
    end

    def update_photo
      photo.update!(
        storage_filename:,
        yandex_token: token_for_upload,
        local_filename: nil,
        folder_index:
      )

      FileUtils.rm_f(local_file)
    end

    def dir_with_index
      @dir_with_index ||=
        if folder_index.nonzero?
          "#{token_for_upload.dir}#{folder_index}"
        else
          token_for_upload.dir
        end
    end
  end
end
