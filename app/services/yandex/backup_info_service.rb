# frozen_string_literal: true

require 'openssl'

module Yandex
  # echo '...' | openssl aes-256-cbc -a -d -K $(echo -n 'secret' | sha256sum | awk '{ print $1 }') \
  #   -iv $(echo -n 'max@mail.mytm.tk' | md5sum | awk '{ print $1 }')
  class BackupInfoService
    include ::Interactor

    WrongResourceError = Class.new(StandardError)
    RESOURCE_DIRS = {
      photo: :dir,
      other: :other_dir
    }.with_indifferent_access.freeze

    delegate :token, :resource, :info, :backup_secret, to: :context

    def call
      validate

      encryptor = new_cipher
      context.info = Base64.encode64(
        encryptor.update("#{download_url}\t#{token.access_token}") + encryptor.final
      ).gsub(/[[:space:]]/, '')
    end

    private

    def download_url
      YandexClient::Disk[token.access_token].download_url(path)
    end

    def path
      @path ||= token.public_send(RESOURCE_DIRS.fetch(resource))
    rescue KeyError
      raise WrongResourceError, "wrong resource passed: \"#{resource}\""
    end

    def new_cipher
      OpenSSL::Cipher.new('aes-256-cbc').encrypt.tap do |cipher|
        cipher.key = Digest::SHA256.digest(backup_secret)
        cipher.iv = Digest::MD5.digest(token.login)
      end
    end

    def validate
      raise 'backup secret not found in credentials' if backup_secret.blank?
      raise "no dir for #{resource} for token #{token.id}" if path.blank?
    end
  end
end
