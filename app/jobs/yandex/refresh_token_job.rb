# frozen_string_literal: true

module Yandex
  class RefreshTokenJob
    include Sidekiq::Worker
    sidekiq_options queue: :tokens

    def perform(token_id)
      token = Token.find(token_id)

      Rails.application.redlock.lock!("yandex_token:#{token_id}:refresh", 30.seconds.in_milliseconds) do
        RefreshToken.call!(token:)
      end
    end
  end
end
