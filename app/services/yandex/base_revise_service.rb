# frozen_string_literal: true

module Yandex
  class BaseReviseService
    include ::Interactor

    delegate :token, :errors, to: :context

    def call
      context.errors ||= {}

      revise

      errors[nil] = dav_response.keys unless dav_response.empty?
    rescue YandexClient::NotFoundError
      errors[nil] = ["dir #{storage_dir} not found on remote storage"]
    end

    private

    def base_storage_dir
      raise 'not implemented'
    end

    def dav_response
      @dav_response ||= ::YandexClient::Dav[token.access_token].
        propfind(storage_dir, 1).
        select(&:file?).
        index_by { |info| info.name.sub(%r{^#{base_storage_dir}/}, '') }
    end

    def match_info(model, dav_info)
      [].tap do |errors|
        errors << 'size mismatch' if model.size != dav_info.size
        errors << 'etag mismatch' if model.md5 != dav_info.etag
      end
    end

    def relation_to_revise
      raise 'not implemented'
    end

    def revise
      relation_to_revise.each_instance { |model| check_model(model) }
    end

    def check_model(model)
      dav_info = dav_response.delete(model.storage_filename)

      if dav_info.nil?
        errors[model_id(model)] = ['not found on the remote storage']
        return
      end

      return if (er = match_info(model, dav_info)).blank?

      errors[model_id(model)] = er
    end

    def storage_dir
      @storage_dir ||= base_storage_dir
    end

    def model_id(model)
      [model.class.name.underscore, model.id].join(':')
    end
  end
end
