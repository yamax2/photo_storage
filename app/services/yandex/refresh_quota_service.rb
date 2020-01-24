# frozen_string_literal: true

module Yandex
  class RefreshQuotaService
    include ::Interactor

    delegate :token, to: :context

    def call
      response = YandexClient::Disk::Client.new(access_token: token.access_token).info

      token.update!(
        used_space: response.fetch(:used_space),
        total_space: response.fetch(:total_space)
      )
    end
  end
end
