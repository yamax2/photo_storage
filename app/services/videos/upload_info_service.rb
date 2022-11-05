# frozen_string_literal: true

module Videos
  class UploadInfoService
    attr_reader :model

    def initialize(model, skip_original: false, secret: Rails.application.credentials.backup_secret)
      @model = model
      @secret = secret
      @skip_original = skip_original
    end

    def call
      Retry.for(:yandex) { create_remote_dir }

      content = {}

      content[:video] = upload_url_for(model.storage_filename) unless @skip_original
      content[:preview] = upload_url_for(model.preview_filename)
      content[:video_preview] = upload_url_for(model.video_preview_filename)

      generate_secret(content)
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

    def generate_secret(content)
      encryptor = new_cipher

      Base64.encode64(
        encryptor.update(content.to_json) + encryptor.final
      ).gsub(/[[:space:]]/, '')
    end

    def new_cipher
      OpenSSL::Cipher.new('aes-256-cbc').encrypt.tap do |cipher|
        cipher.key = Digest::SHA256.digest(@secret)
        cipher.iv = Digest::MD5.digest(model.original_filename)
      end
    end

    def upload_url_for(filename)
      Retry.for(:yandex) do
        ::YandexClient::Disk[model.yandex_token.access_token].
          upload_url([dir_with_index, filename].join('/'), overwrite: true)
      end
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
