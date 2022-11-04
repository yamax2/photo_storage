# frozen_string_literal: true

module Admin
  module Yandex
    class TokensController < AdminController
      before_action :find_token, only: %i[edit update destroy refresh]

      def index
        @new_token_url =
          'https://oauth.yandex.ru/authorize?response_type=' \
          "code&client_id=#{YandexClient.config.api_key}&force_confirm=false"

        @search = ::Yandex::TokenSummaryFinder.call.ransack(params[:q])
        @tokens = @search.result.page(params[:page])
      end

      def edit
      end

      def update
        if @token.update(token_params)
          redirect_to action: :index
        else
          render 'edit'
        end
      end

      def refresh
        ::Yandex::RefreshTokenJob.perform_async(@token.id)

        redirect_to admin_yandex_tokens_path, notice: t('.success', login: @token.login)
      end

      def destroy
        @token.destroy

        redirect_to admin_yandex_tokens_path, notice: t('.success', login: @token.login)
      end

      private

      def find_token
        @token = ::Yandex::Token.find(params[:id])
      end

      def token_params
        params.
          require(:yandex_token).
          permit(
            :dir, :other_dir, :active,
            :photos_folder_index, :other_folder_index,
            :photos_folder_archive_from, :other_folder_archive_from
          ).tap do |values|
            %i[photos_folder_index other_folder_index photos_folder_archive_from other_folder_archive_from].
              each { |attr| values[attr] = values[attr].to_i if values[attr] }
          end
      end
    end
  end
end
