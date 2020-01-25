# frozen_string_literal: true

require 'openssl'

module Yandex
  # echo '...' | openssl aes-256-cbc -a -d -K $(echo -n 'secret' | sha256sum | awk '{ print $1 }') \
  #   -iv $(echo -n 'max@mail.mytm.tk' | md5sum | awk '{ print $1 }')
  class BackupInfoService
    WrongResourceError = Class.new(StandardError)

    RESOURCE_DIRS = {
      photos: :dir,
      other: :other_dir
    }.with_indifferent_access.freeze

    def initialize(token, resource)
      @token = token
      @path = find_path(resource)

      raise 'backup secret not found in credentials' if backup_secret.blank?
      raise "no dir for #{resource} for token #{@token.id}" if @path.blank?
    end

    def call
      encryptor = new_cipher

      value = "#{download_url}\t#{@token.access_token}"

      Base64.encode64(
        encryptor.update(value) + encryptor.final
      ).gsub(/[[:space:]]/, '')
    end

    private

    delegate :backup_secret, to: 'Rails.application.credentials'

    def download_url
      YandexClient::Disk::Client.
        new(access_token: @token.access_token).
        download_url(path: @path).
        fetch(:href)
    end

    def find_path(resource)
      @token.public_send(RESOURCE_DIRS.fetch(resource))
    rescue KeyError
      raise WrongResourceError, "wrong resource passed: \"#{resource}\""
    end

    def new_cipher
      OpenSSL::Cipher::AES256.new(:CBC).encrypt.tap do |cipher|
        cipher.key = Digest::SHA256.digest(backup_secret)
        cipher.iv = Digest::MD5.digest(@token.login)
      end
    end
  end
end
