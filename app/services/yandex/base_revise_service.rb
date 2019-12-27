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
      return @dav_response if defined?(@dav_response)

      client = YandexClient::Dav::Client.new(access_token: token.access_token)

      @dav_response = client.
        propfind(name: storage_dir, depth: 1).
        delete_if { |_, info| info[:resourcetype] == :folder }.
        transform_keys do |key|
        key.sub(%r{^#{base_storage_dir}/}, '')
      end
    end

    def match_info(model, dav_info)
      [].tap do |errors|
        errors << 'size mismatch' if model.size != dav_info.fetch(:getcontentlength)
        errors << 'etag mismatch' if model.md5 != dav_info.fetch(:getetag)
      end
    end

    def relation_to_revise
      raise 'not implemented'
    end

    def revise
      relation_to_revise.each do |model|
        dav_info = dav_response.delete(model.storage_filename)

        if dav_info.nil?
          errors[model.id] = ['not found on remote storage']
          next
        end

        next if (er = match_info(model, dav_info)).blank?

        errors[model.id] = er
      end
    end

    def storage_dir
      @storage_dir ||= base_storage_dir
    end
  end
end
