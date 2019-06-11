module Admin
  module Yandex
    class TokensController < AdminController
      def index
        @new_token_url = "https://oauth.yandex.ru/authorize?response_type=" \
          "code&client_id=#{YandexPhotoStorage.config.api_key}&force_confirm=false"

        @tokens = ::Yandex::Token.all.page(params[:page])
      end
    end
  end
end
