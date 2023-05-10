# frozen_string_literal: true

module Yandex
  class RefreshQuotaService
    include ::Interactor

    delegate :token, to: :context, private: true

    def call
      response = Retry.for(:yandex) { YandexClient::Disk[token.access_token].info }

      token.update!(
        used_space: response.fetch(:used_space),
        total_space: response.fetch(:total_space)
      )

      Rails.application.redis.call('HDEL', TokenForUploadService::CACHE_REDIS_KEY, token.id)
    end
  end
end
