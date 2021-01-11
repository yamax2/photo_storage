# frozen_string_literal: true

module ProxyUrls
  class Photo
    attr_reader :model

    def initialize(model)
      @model = model
    end

    def generate(size = :original, thumb_width = nil)
      return if storage_filename.blank?

      path = "#{yandex_token.dir.sub(%r{^/}, '')}/#{storage_filename}"
      method = size == :original ? :proxy_object_path : :proxy_object_preview_path

      Rails.application.routes.url_helpers.public_send(method, path, params_for_size(size, thumb_width))
    end

    private

    delegate :yandex_token, :yandex_token_id, :original_filename, :storage_filename, to: :model

    def params_for_size(size, thumb_width)
      {id: yandex_token_id}.tap do |params|
        if size == :original
          params[:fn] = original_filename
        else
          params[:size] = thumb_width
        end
      end
    end
  end
end
