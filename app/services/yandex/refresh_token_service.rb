# frozen_string_literal: true

module Yandex
  class RefreshTokenService
    include ::Interactor

    TOKEN_REFRESH_PERIOD = 3.days

    delegate :token, to: :context

    def call
      return unless token.valid_till - TOKEN_REFRESH_PERIOD < Time.current

      token.valid_till = Time.current + token_response.delete(:expires_in).seconds
      token.assign_attributes token_response.except!(:token_type)

      save_token
    end

    private

    def save_token
      TokenChangedNotifyJob.perform_async if token.changed? && token.save!
    end

    def token_response
      @token_response ||= YandexClient::Auth::Client.new.refresh_token(refresh_token: token.refresh_token)
    end
  end
end
