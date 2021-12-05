# frozen_string_literal: true

module Video
  class UploadInfoService
    attr_reader :model

    def initialize(model, secret: Rails.application.credentials.backup_secret)
      @model = model
      @secret = secret
    end

    def call
      encryptor = new_cipher
      content = upload_info.to_json

      Base64.encode64(
        encryptor.update(content) + encryptor.final
      ).gsub(/[[:space:]]/, '')
    end

    private

    def new_cipher
      OpenSSL::Cipher.new('aes-256-cbc').encrypt.tap do |cipher|
        cipher.key = Digest::SHA256.digest(@secret)
        cipher.iv = Digest::MD5.digest(model.original_filename)
      end
    end

    def upload_info # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      {
        video: {
          url: url_for(model.storage_filename),
          headers: {
            'Authorization' => auth_header,
            'Content-Length' => model.size,
            'Etag' => model.md5,
            'Sha256' => model.sha256,
            'Expect' => '100-continue'
          }
        },
        preview: {
          url: url_for(model.preview_filename),
          headers: {
            'Authorization' => auth_header,
            'Content-Length' => model.preview_size,
            'Etag' => model.preview_md5,
            'Sha256' => model.preview_sha256,
            'Expect' => '100-continue'
          }
        }
      }
    end

    def auth_header
      @auth_header ||= "OAuth #{model.yandex_token.access_token}"
    end

    def url_for(filename)
      "#{YandexClient::Dav::ACTION_URL}#{model.yandex_token.other_dir}/#{filename}"
    end
  end
end
