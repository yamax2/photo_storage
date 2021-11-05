# frozen_string_literal: true

module ProxyUrls
  class Photo
    YANDEX_MAX_DIMENSION = 1_280
    private_constant :YANDEX_MAX_DIMENSION

    attr_reader :model

    def initialize(model)
      @model = model
    end

    def generate(size = :original, dimensions = nil)
      return if storage_filename.blank?

      Rails.application.routes.url_helpers.public_send(
        proxy_method(size, dimensions),
        "#{yandex_token.dir.sub(%r{^/}, '')}/#{storage_filename}",
        params_for_size(size, dimensions&.first)
      )
    end

    private

    delegate :yandex_token, :yandex_token_id, :original_filename, :storage_filename, to: :model, private: true

    def params_for_size(size, thumb_width)
      {id: yandex_token_id}.tap do |params|
        if size == :original
          params[:fn] = original_filename
        else
          params[:size] = thumb_width
        end
      end
    end

    def proxy_method(size, dimensions)
      if size == :original
        :proxy_yandex_object_path
      elsif dimensions && dimensions.max > YANDEX_MAX_DIMENSION
        :proxy_yandex_object_resize_path
      else
        :proxy_yandex_object_preview_path
      end
    end
  end
end
