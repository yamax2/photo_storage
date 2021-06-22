# frozen_string_literal: true

module Photos
  class RemoveService
    include ::Interactor

    delegate :storage_filename, :yandex_token, to: :context

    def call
      ::YandexClient::Dav[yandex_token.access_token].
        delete([yandex_token.dir, storage_filename].join('/'))
    rescue ::YandexClient::NotFoundError
      false
    end
  end
end
