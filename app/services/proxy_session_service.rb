# frozen_string_literal: true

require 'openssl'
require 'oj'

# just for fun
class ProxySessionService
  SESSION_TTL = 90.days
  MD5_LENGTH = 16

  def initialize(session = nil)
    if proxy.nil? || proxy[:secret].nil? || proxy[:iv].nil? || proxy[:iv].to_s.length != MD5_LENGTH
      settings_validation_error
    end

    @session = session if session
  end

  def call
    generate_session if @session.blank? || need_generate?
  end

  private

  delegate :proxy, to: 'Rails.application.credentials'

  def cipher(operation)
    OpenSSL::Cipher::AES256.new(:CBC).public_send(operation).tap do |cipher|
      cipher.key = Digest::MD5.hexdigest(proxy.fetch(:secret))
      cipher.iv = proxy.fetch(:iv)
    end
  end

  def generate_session
    encryptor = cipher(:encrypt)

    till = (Time.current + SESSION_TTL).to_i
    value = "#{Oj.dump({till: till}, mode: :json)}#{[till].pack('Q').reverse}"

    @session = Base64.encode64(
      Digest::MD5.digest(value) + encryptor.update(value) + encryptor.final
    ).gsub(/[[:space:]]/, '')
  end

  def need_generate?
    decryptor = cipher(:decrypt)

    value = Base64.decode64(@session)
    md5 = value.first(MD5_LENGTH)

    value = decryptor.update(value[MD5_LENGTH..-1]) + decryptor.final
    return true unless md5 == Digest::MD5.digest(value)

    # remove last 8 bytes
    payload = Oj.load(value[0..-9], symbol_keys: true, mode: :json)
    payload.fetch(:till) < Time.current.to_i
  rescue StandardError
    true
  end

  def settings_validation_error
    raise <<~MSG
      Proxy session settings not found.
      Provide "proxy.secret" and "proxy.iv" values in rails credential file.
    MSG
  end
end
