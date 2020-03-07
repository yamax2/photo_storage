# frozen_string_literal: true

module Yandex
  # https://oauth.yandex.ru/authorize?response_type=code&client_id=<client_id>&force_confirm=false
  class CreateOrUpdateTokenService
    include ::Interactor

    delegate :code, :token, to: :context

    def call
      find_token

      token.assign_attributes(passport_response.slice(:login))
      token.assign_attributes(token_response)

      changed = token.changed?

      token.save!

      perform_refresh if changed
    end

    private

    def find_token
      context.token = Token.find_or_initialize_by(user_id: passport_response.delete(:id))

      token.valid_till = Time.current + token_response.delete(:expires_in).seconds
    end

    def passport_response
      @passport_response ||=
        YandexClient::Passport::Client.new(access_token: token_response.fetch(:access_token)).info
    end

    def perform_refresh
      TokenChangedNotifyJob.perform_async
      RefreshTokenJob.perform_async(token.id)
    end

    def token_response
      @token_response ||= YandexClient::Auth::Client.new.create_token(code: code)
    end
  end
end
