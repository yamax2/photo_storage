# frozen_string_literal: true

module Tracks
  class UploadService
    include ::Interactor

    delegate :track, :storage_filename, :folder_index, to: :context, private: true

    def call
      return if track.storage_filename.present?

      validate_upload

      context.storage_filename ||= StorageFilenameGenerator.call(track, partition: false)
      context.folder_index = token_for_upload.other_folder_index.to_i

      create_remote_dir
      upload_file
      update_track
    end

    private

    def client
      @client ||= ::YandexClient::Dav[token_for_upload.access_token]
    end

    def create_remote_dir
      client.propfind(dir_with_index)
    rescue ::YandexClient::NotFoundError
      client.mkcol(dir_with_index)
    end

    def local_file
      @local_file ||= track.tmp_local_filename
    end

    def token_for_upload
      @token_for_upload ||= Yandex::Token.where(
        id: Yandex::TokenForUploadService.call!(resource_size: track.size).token_id
      ).first
    end

    def upload_file
      client.put(
        local_file,
        "#{dir_with_index}/#{storage_filename}",
        size: track.size,
        etag: track.md5,
        sha256: track.sha256
      )
    end

    def validate_upload
      context.fail!(message: 'local file not found') unless track.local_file?
      context.fail!(message: 'active token not found') if token_for_upload.blank?
    end

    def update_track
      track.update!(
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
          "#{token_for_upload.other_dir}#{folder_index}"
        else
          token_for_upload.other_dir
        end
    end
  end
end
