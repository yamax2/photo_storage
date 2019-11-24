# frozen_string_literal: true

require 'openssl'
require 'oj'

module ProxySessionHelper
  def generate_proxy_session(till = (Time.current + 90.days).to_i, custom_json: nil)
    cipher = OpenSSL::Cipher::AES256.new(:CBC).encrypt

    cipher.key = Digest::MD5.hexdigest(Rails.application.credentials.proxy.fetch(:secret))
    cipher.iv = Rails.application.credentials.proxy.fetch(:iv)

    value = "#{Oj.dump(custom_json || {till: till}, mode: :json)}#{[till].pack('Q').reverse}"
    session = Base64.encode64(
      Digest::MD5.digest(value) + cipher.update(value) + cipher.final
    ).gsub(/[[:space:]]/, '')

    CGI.escape(session)
  end
end
