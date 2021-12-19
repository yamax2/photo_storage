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
      content = {}

      content[:video] = upload_url_for(model.storage_filename) unless @skip_original
      content[:preview] = upload_url_for(model.preview_filename)
      content[:video_preview] = upload_url_for(model.video_preview_filename)

      generate_secret(content)
    end

    private

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
      node = model.yandex_token

      ::YandexClient::Disk[node.access_token].
        upload_url([node.other_dir, filename].join('/'), overwrite: true)
    end
  end
end
