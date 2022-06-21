# frozen_string_literal: true

module Yandex
  class RefreshTokenService
    include ::Interactor

    TOKEN_REFRESH_PERIOD = 3.days

    delegate :token, to: :context

    def call
      return unless token.valid_till - TOKEN_REFRESH_PERIOD < Time.current

      token.valid_till = valid_till
      token.assign_attributes token_response.except!(:token_type, :scope)

      token.save!
    end

    private

    def token_response
      @token_response ||= YandexClient.auth.refresh_token(token.refresh_token)
    end

    def valid_till
      Time.current + token_response.delete(:expires_in).seconds
    end
  end
end
