# frozen_string_literal: true

module Api
  module V1
    module Admin
      class VideosController < AdminController
        def create
          @video = Photo.new(normalized_video_params)

          ::Videos::StoreService.new(@video).call

          if @video.video? && @video.save
            enqueue_jobs

            render status: :created
          else
            render status: :unprocessable_entity
          end
        end

        def show
          @video = Photo.videos.find(params[:id])

          if (info = RedisClassy.get(info_redis_key)).present?
            render plain: info
          else
            render status: :gone, json: {}
          end
        end

        private

        def video_params
          params.
            require(:video).
            permit(
              :name, :rubric_id, :content_type, :original_filename, :original_timestamp, :width, :height,
              :md5, :sha256, :preview_md5, :preview_sha256, :video_preview_md5, :video_preview_sha256,
              :size, :preview_size, :video_preview_size,
              :tz, :duration, lat_long: [], exif: %i[make model]
            )
        end

        def normalized_video_params
          video_params.tap do |par|
            par[:preview_size] = par[:preview_size].to_i
            par[:video_preview_size] = par[:video_preview_size].to_i
            par[:duration] = par[:duration].to_f if par[:duration].present?
          end
        end

        def enqueue_jobs
          with_redis_transaction do
            ::Photos::EnqueueLoadDescriptionService.call!(photo: @video)

            temporary_filename = params[:temporary_uploaded_filename]

            if temporary_filename.present?
              ::Videos::MoveOriginalJob.perform_async \
                @video.id, temporary_filename
            end

            ::Videos::UploadInfoJob.perform_async(@video.id, info_redis_key, temporary_filename.present?)
          end
        end

        def with_redis_transaction(&block)
          Sidekiq.redis { |redis| redis.multi(&block) }
        end

        def info_redis_key
          "video_upload:#{@video.id}"
        end
      end
    end
  end
end
