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
        "#{yandex_token.other_dir.sub(%r{^/}, '')}/#{storage_filename}",
        {
          id: yandex_token_id,
          fn: original_filename
        }
    end

    delegate :storage_filename, :yandex_token, :yandex_token_id, :original_filename, to: :model, private: true
  end
end
