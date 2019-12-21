# frozen_string_literal: true

module Admin
  module Yandex
    class TokensController < AdminController
      before_action :find_token, only: %i[edit update destroy refresh]

      def destroy
        @token.destroy

        redirect_to admin_yandex_tokens_path, notice: t('.success', login: @token.login)
      end

      def edit
      end

      def index
        @new_token_url = 'https://oauth.yandex.ru/authorize?response_type=' \
          "code&client_id=#{YandexClient.config.api_key}&force_confirm=false"

        @search = ::Yandex::Token.ransack(params[:q])
        @tokens = @search.result.page(params[:page])
      end

      def refresh
        ::Yandex::RefreshTokenJob.perform_async(@token.id)

        redirect_to admin_yandex_tokens_path, notice: t('.success', login: @token.login)
      end

      def update
        if @token.update(token_params)
          redirect_to action: :index
        else
          render 'edit'
        end
      end

      private

      def find_token
        @token = ::Yandex::Token.find(params[:id])
      end

      def token_params
        params.require(:yandex_token).permit(:dir, :other_dir, :active)
      end
    end
  end
end
