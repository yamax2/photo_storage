# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Internal route with nodes list for proxy service
      class NodesController < AdminController
        def show
          @node = ::Yandex::Token.find(params[:id])

          encryptor = new_cipher(@node)

          @secret = Base64.encode64(
            encryptor.update(@node.access_token) + encryptor.final
          ).gsub(/[[:space:]]/, '')
        end

        private

        def new_cipher(node)
          OpenSSL::Cipher.new('aes-256-cbc').encrypt.tap do |cipher|
            cipher.key = Digest::SHA256.digest(Rails.application.credentials.backup_secret)
            cipher.iv = Digest::MD5.digest(node.login)
          end
        end
      end
    end
  end
end
