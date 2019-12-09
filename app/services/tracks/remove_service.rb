# frozen_string_literal: true

module Tracks
  class RemoveService
    include ::Interactor

    delegate :storage_filename, :yandex_token, to: :context

    def call
      client.delete(name: [yandex_token.other_dir, storage_filename].join('/'))
    rescue ::YandexClient::NotFoundError
      false
    end

    private

    def client
      @client ||= ::YandexClient::Dav::Client.new(access_token: yandex_token.access_token)
    end
  end
end
