# frozen_string_literal: true

module Photos
  class UploadService
    include ::Interactor

    delegate :photo, :storage_filename, to: :context

    def call
      return if photo.storage_filename.present?

      validate_upload

      context.storage_filename ||= StorageFilenameGenerator.call(photo)

      create_remote_dirs
      upload_file
      update_photo
    end

    private

    def client
      @client ||= ::YandexClient::Dav[token_for_upload.access_token]
    end

    def create_remote_dir(path)
      client.propfind(path)
    rescue ::YandexClient::NotFoundError
      client.mkcol(path)
    end

    def create_remote_dirs
      return if remote_path_exists?

      RedisMutex.with_lock(
        "yandex:dirs:#{token_for_upload.id}:#{remote_path.join(':')}",
        block: 1.minute, expire: 10.minutes
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

      @remote_path = token_for_upload.dir.split('/') + storage_filename.split('/')

      @remote_path.pop
      @remote_path.delete_if(&:empty?)

      @remote_path
    end

    def remote_path_exists?
      client.propfind("/#{remote_path.join('/')}")

      true
    rescue ::YandexClient::NotFoundError
      false
    end

    def token_for_upload
      @token_for_upload ||= Yandex::Token.where(
        id: Yandex::TokenForUploadService.call!(resource_size: photo.size).token_id
      ).first
    end

    def upload_file
      client.put(
        local_file,
        "#{token_for_upload.dir}/#{storage_filename}",
        size: photo.size,
        etag: photo.md5,
        sha256: photo.sha256
      )
    end

    def validate_upload
      context.fail!(message: 'local file not found') unless photo.local_file?
      context.fail!(message: 'active token not found') if token_for_upload.blank?
    end

    def update_photo
      photo.update!(
        storage_filename: storage_filename,
        yandex_token: token_for_upload,
        local_filename: nil
      )

      FileUtils.rm_f(local_file)
    end
  end
end
