# frozen_string_literal: true

module Yandex
  class ReviseDirService < BaseReviseService
    include ::Interactor

    delegate :dir, to: :context

    private

    def base_storage_dir
      if folder_index.nonzero?
        "#{token.dir}#{folder_index}"
      else
        token.dir
      end
    end

    def match_info(model, dav_info)
      super.tap do |errors|
        errors << 'content type mismatch' if model.content_type != dav_info.content_type
      end
    end

    def relation_to_revise
      Photo.
        uploaded.
        images.
        where(yandex_token: token, folder_index:).
        where(Photo.arel_table[:storage_filename].matches_regexp("^#{dir}[a-z0-9]+\.[A-z]+$"))
    end

    def storage_dir
      @storage_dir ||= "#{base_storage_dir}/#{dir}"
    end
  end
end
