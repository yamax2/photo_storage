# frozen_string_literal: true

require 'openssl'
require 'oj'

# just for fun
class ProxySessionService
  SESSION_TTL = 1.month

  def initialize(session = nil)
    if Rails.application.credentials.proxy[:secret].nil?
      raise <<~MSG
        Proxy session secret is empty.
        Provide "proxy.secret" value in rails credential file.
      MSG
    end

    @session = session
  end

  def call
    generate_session if !@session.present? || need_generate?
  end

  private

  def cipher(operation)
    OpenSSL::Cipher::AES256.new(:CBC).public_send(operation).tap do |cipher|
      cipher.key = Digest::SHA256.digest(Rails.application.credentials.proxy.fetch(:secret))
      cipher.iv = Digest::MD5.digest(Rails.application.routes.default_url_options[:host])
    end
  end

  def generate_session
    encryptor = cipher(:encrypt)

    @session = Base64.urlsafe_encode64(
      encryptor.update(Oj.dump({till: (Time.current + SESSION_TTL).to_i}, mode: :json)) + encryptor.final,
      padding: false
    )
  end

  def need_generate?
    decryptor = cipher(:decrypt)

    payload = Oj.load(
      decryptor.update(Base64.urlsafe_decode64(@session)) + decryptor.final,
      symbol_keys: true,
      mode: :json
    )

    payload.fetch(:till) < Time.current.to_i
  rescue StandardError
    true
  end
end
