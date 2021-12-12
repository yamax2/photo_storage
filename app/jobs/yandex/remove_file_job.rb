# frozen_string_literal: true

module Yandex
  class RemoveFileJob
    include Sidekiq::Worker

    def perform(node_id, full_storage_filename)
      node = Yandex::Token.find(node_id)

      ::YandexClient::Dav[node.access_token].delete(full_storage_filename)
    rescue ::YandexClient::NotFoundError
      false
    end
  end
end
