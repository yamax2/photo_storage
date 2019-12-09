# frozen_string_literal: true

module Tracks
  class UploadService
    include ::Interactor

    delegate :track, to: :context

    def call
      return if track.storage_filename.present?

      validate_upload

      @storage_filename = StorageFilenameGenerator.new(track, partition: false).call

      upload_file
      update_track
    end

    private

    def local_file
      @local_file ||= track.tmp_local_filename
    end

    def token_for_upload
      @token_for_upload ||= Yandex::Token.active.first
    end

    def upload_file
      ::YandexClient::Dav::Client.
        new(access_token: token_for_upload.access_token).
        put(
          file: local_file,
          name: "#{token_for_upload.other_dir}/#{@storage_filename}",
          size: track.size,
          md5: track.md5,
          sha256: track.sha256
        )
    end

    def validate_upload
      context.fail!(message: 'local file not found') unless track.local_file?
      context.fail!(message: 'active token not found') unless token_for_upload.present?
    end

    def update_track
      track.update!(
        storage_filename: @storage_filename,
        yandex_token: token_for_upload,
        local_filename: nil
      )

      FileUtils.rm_f(local_file)
    end
  end
end
