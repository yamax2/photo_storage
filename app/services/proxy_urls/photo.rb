# frozen_string_literal: true

module ProxyUrls
  class Photo
    YANDEX_MAX_IMAGE_DIMENSION = 1_280
    private_constant :YANDEX_MAX_IMAGE_DIMENSION

    attr_reader :model

    def initialize(model)
      @model = model
    end

    def generate(size = :original, dimensions = nil)
      return if storage_filename.blank?

      if video?
        video_url(size, dimensions)
      else
        photo_url(size, dimensions)
      end
    end

    private

    delegate :yandex_token,
             :yandex_token_id,
             :original_filename,
             :storage_filename,
             :preview_filename,
             :video_preview_filename,
             :video?,
             to: :model, private: true

    def params_for_size(size, thumb_width)
      {id: yandex_token_id}.tap do |params|
        if original?(size)
          params[:fn] = original_filename
        else
          params[:size] = thumb_width
        end
      end
    end

    def proxy_method(size, dimensions)
      if original?(size) || size == :video_preview
        :proxy_yandex_object_path
      elsif dimensions && dimensions.max > YANDEX_MAX_IMAGE_DIMENSION
        :proxy_yandex_object_resize_path
      else
        :proxy_yandex_object_preview_path
      end
    end

    def video_url(size, dimensions) # rubocop:disable Metrics/MethodLength
      actual_filename =
        if original?(size)
          storage_filename
        elsif size == :video_preview
          video_preview_filename
        else
          preview_filename
        end

      Rails.application.routes.url_helpers.public_send(
        proxy_method(size, dimensions),
        "#{dir_with_index(:other_dir)}/#{actual_filename}",
        params_for_size(size, dimensions&.first)
      )
    end

    def photo_url(size, dimensions)
      Rails.application.routes.url_helpers.public_send(
        proxy_method(size, dimensions),
        "#{dir_with_index(:dir)}/#{storage_filename}",
        params_for_size(size, dimensions&.first)
      )
    end

    def original?(size)
      size == :original
    end

    def dir_with_index(dir_type)
      dir = yandex_token.public_send(dir_type).sub(%r{^/}, '')

      return dir unless model.folder_index.nonzero?

      "#{dir}#{model.folder_index}"
    end
  end
end
