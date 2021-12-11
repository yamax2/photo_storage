# frozen_string_literal: true

module Video
  class UploadInfoService
    attr_reader :model

    def initialize(model, secret: Rails.application.credentials.backup_secret)
      @model = model
      @secret = secret
    end

    def call
      content = {
        video: upload_url_for(model.storage_filename),
        preview: upload_url_for(model.preview_filename)
      }.to_json

      encryptor = new_cipher

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

    def upload_url_for(filename)
      node = model.yandex_token

      ::YandexClient::Disk[node.access_token].
        upload_url([node.other_dir, filename].join('/'), overwrite: true)
    end
  end
end
