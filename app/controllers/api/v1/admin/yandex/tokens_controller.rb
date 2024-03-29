# frozen_string_literal: true

module Api
  module V1
    module Admin
      module Yandex
        class TokensController < AdminController
          # dumb api for my NAS :-)
          def index
            @resources = resource_scope.active.each_with_object([]) do |token, memo|
              resource = {token:}

              memo << resource.merge(type: :photo) if archive_photos?(token)
              memo << resource.merge(type: :other) if archive_other?(token)
            end

            assign_last_marks
          end

          def show
            @resource = params.require(:resource)
            @token = current_token

            @info = ::Yandex::EnqueueBackupInfoService.call!(
              token: @token,
              resource: @resource,
              folder_index: @token.folder_index,
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

          def archive_other?(token)
            token.other_count.present? &&
              token.folder_index >= token.other_folder_archive_from.to_i
          end

          def archive_photos?(token)
            token.photo_count.present? &&
              token.folder_index >= token.photos_folder_archive_from.to_i
          end

          def resource_scope
            ::Yandex::ResourceFinder.call
          end

          def current_token
            resource_scope.where(
              id: params[:id],
              resources: {folder_index: params.require(:folder_index)}
            ).first!
          end

          def assign_last_marks
            @resources.each_with_index do |resource, index|
              next_item = @resources[index + 1]

              resource[:is_last] = resource[:token].id != next_item&.[](:token)&.id
            end
          end
        end
      end
    end
  end
end
