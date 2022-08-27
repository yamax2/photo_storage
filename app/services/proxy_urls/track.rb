# frozen_string_literal: true

module ProxyUrls
  class Track
    attr_reader :model

    def initialize(model)
      @model = model
    end

    def generate
      return if storage_filename.blank?

      Rails.application.routes.url_helpers.proxy_yandex_object_path \
        "#{dir_with_index}/#{storage_filename}",
        {
          id: yandex_token_id,
          fn: original_filename
        }
    end

    delegate :storage_filename, :yandex_token, :yandex_token_id, :original_filename, to: :model, private: true

    private

    def dir_with_index
      dir = yandex_token.other_dir.sub(%r{^/}, '')

      return dir unless model.folder_index.nonzero?

      "#{dir}#{model.folder_index}"
    end
  end
end
