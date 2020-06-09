# frozen_string_literal: true

module Api
  module V1
    module Admin
      module Yandex
        class TokensController < BaseController
          # dumb api for my NAS :-)
          def index
            @resources = ::Yandex::ResourceFinder.call.each_with_object([]) do |token, memo|
              resource = {token: token}

              memo << resource.merge(type: :photos) if token.photos_present
              memo << resource.merge(type: :other) if token.other_present
            end
          end

          def show
            @token = ::Yandex::Token.find(params[:id])

            @resource = ::Yandex::EnqueueBackupInfoService.call!(
              token: @token,
              resource: params.require(:resource),
              backup_secret: Rails.application.credentials.backup_secret
            ).info

            head :accepted if @resource.blank?
          end
        end
      end
    end
  end
end
