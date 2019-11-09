# frozen_string_literal: true

module ProxySessionHelper
  def generate_proxy_session(for_text)
    cipher = OpenSSL::Cipher::AES256.new(:CBC).encrypt

    cipher.key = Digest::SHA256.digest(Rails.application.credentials.proxy.fetch(:secret))
    cipher.iv = Digest::MD5.digest(Rails.application.routes.default_url_options[:host])

    Base64.urlsafe_encode64(cipher.update(for_text) + cipher.final)
  end
end
