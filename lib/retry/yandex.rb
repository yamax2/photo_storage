# frozen_string_literal: true

Retry.register(
  :yandex,
  [
    HTTP::Error,
    OpenSSL::SSL::SSLError
  ]
)
