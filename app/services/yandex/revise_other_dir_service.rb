# frozen_string_literal: true

module Yandex
  class ReviseOtherDirService < BaseReviseService
    private

    def revise
      super

      videos_to_revise.each_instance do |model|
        check_model(model)
        check_preview(model)
      end
    end

    def base_storage_dir
      token.other_dir
    end

    def relation_to_revise
      token.tracks.uploaded
    end

    def videos_to_revise
      token.photos.videos.uploaded
    end

    def check_preview(model)
      dav_info = dav_response.delete(model.preview_filename)
      id = model_id(model)

      if dav_info.nil?
        (errors[id] ||= []) << 'preview not found on the remote storage'

        return
      end

      return if (er = match_preview_info(model, dav_info)).blank?

      (errors[id] ||= []).concat(er)
    end

    def match_preview_info(model, dav_info)
      [].tap do |errors|
        errors << 'preview size mismatch' if model.preview_size.to_i != dav_info.size
        errors << 'preview etag mismatch' if model.preview_md5 != dav_info.etag
      end
    end
  end
end
