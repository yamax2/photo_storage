# frozen_string_literal: true

module Tracks
  class UploadService
    include ::Interactor

    delegate :track, :storage_filename, to: :context

    def call
      return if track.storage_filename.present?

      validate_upload

      context.storage_filename ||= StorageFilenameGenerator.call(track, partition: false)

      upload_file
      update_track
    end

    private

    def local_file
      @local_file ||= track.tmp_local_filename
    end

    def token_for_upload
      @token_for_upload ||= Yandex::Token.where(
        id: Yandex::TokenForUploadService.call!(resource_size: track.size).token_id
      ).first
    end

    def upload_file
      ::YandexClient::Dav[token_for_upload.access_token].
        put(
          local_file,
          "#{token_for_upload.other_dir}/#{storage_filename}",
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
        storage_filename: storage_filename,
        yandex_token: token_for_upload,
        local_filename: nil
      )

      FileUtils.rm_f(local_file)
    end
  end
end
