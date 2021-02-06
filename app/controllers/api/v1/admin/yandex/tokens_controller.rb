# frozen_string_literal: true

module Api
  module V1
    module Admin
      module Yandex
        class TokensController < AdminController
          # dumb api for my NAS :-)
          def index
            @resources = resource_scope.active.each_with_object([]) do |token, memo|
              resource = {token: token}

              # photos always last element
              memo << resource.merge(type: :track) if token.track_count.present?
              memo << resource.merge(type: :photo) if token.photo_count.present?
            end
          end

          def show
            @resource = params.require(:resource)
            @token = resource_scope.find(params[:id])

            @info = ::Yandex::EnqueueBackupInfoService.call!(
              token: @token,
              resource: @resource,
              backup_secret: Rails.application.credentials.backup_secret
            ).info

            head :accepted if @info.blank?
          end

          def touch
            @token = ::Yandex::Token.find(params[:id])
            @token.last_archived_at = Time.current

            if @token.save
              render status: :accepted
            else
              head :unprocessable_entity
            end
          end

          private

          def resource_scope
            ::Yandex::ResourceFinder.call
          end
        end
      end
    end
  end
end
