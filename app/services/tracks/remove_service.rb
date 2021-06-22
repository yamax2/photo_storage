# frozen_string_literal: true

module Tracks
  class RemoveService
    include ::Interactor

    delegate :storage_filename, :yandex_token, to: :context

    def call
      ::YandexClient::Dav[yandex_token.access_token].
        delete([yandex_token.other_dir, storage_filename].join('/'))
    rescue ::YandexClient::NotFoundError
      false
    end
  end
end
