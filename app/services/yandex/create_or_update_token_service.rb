module Yandex
  # https://oauth.yandex.ru/authorize?response_type=code&client_id=<client_id>&force_confirm=false
  class CreateOrUpdateTokenService
    include ::Interactor

    delegate :code, :token, to: :context

    def call
      context.token = Token.find_or_initialize_by(user_id: passport_response.delete(:id))

      token.valid_till = Time.current + token_response.delete(:expires_in).seconds
      token.assign_attributes(passport_response.slice(:login))
      token.assign_attributes(token_response)

      token.save!
    end

    private

    def passport_response
      @passport_response ||=
        YandexPhotoStorage::Passport::Client.new(access_token: token_response.fetch(:access_token)).info
    end

    def token_response
      @token_response ||= YandexPhotoStorage::Auth::Client.new.create_token(code: code)
    end
  end
end
