# frozen_string_literal: true

module Api
  module V1
    module Admin
      class VideosController < AdminController
        def create
          @video = Photo.new(normalized_video_params)

          ::Video::StoreService.new(@video).call

          if @video.video? && @video.save
            @info = ::Video::UploadInfoService.new(@video).call
          else
            render status: :unprocessable_entity
          end
        end

        private

        def video_params
          params.
            require(:video).
            permit(
              :name, :rubric_id, :content_type, :original_filename, :original_timestamp, :width, :height,
              :md5, :sha256, :preview_md5, :preview_sha256, :size, :preview_size, :tz,
              lat_long: [], exif: %i[make model]
            )
        end

        def normalized_video_params
          video_params.tap do |par|
            par[:preview_size] = par[:preview_size].to_i
          end
        end
      end
    end
  end
end
