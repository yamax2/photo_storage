# frozen_string_literal: true

module Yandex
  class ReviseOtherDirService < BaseReviseService
    private

    def revise
      super

      videos_to_revise.each_instance do |model|
        check_model(model)

        check_preview(model, model.preview_filename, md5: model.preview_md5, size: model.preview_size)

        check_preview(
          model,
          model.video_preview_filename,
          md5: model.video_preview_md5, size: model.video_preview_size
        )
      end
    end

    def base_storage_dir
      if folder_index.nonzero?
        "#{token.other_dir}#{folder_index}"
      else
        token.other_dir
      end
    end

    def relation_to_revise
      token.tracks.uploaded.where(folder_index:)
    end

    def videos_to_revise
      token.photos.videos.uploaded.where(folder_index:)
    end

    def check_preview(model, filename, md5:, size:)
      dav_info = dav_response.delete(filename)
      id = model_id(model)

      if dav_info.nil?
        (errors[id] ||= []) << "#{filename} not found on the remote storage"

        return
      end

      return if (er = match_preview_info(filename, dav_info, md5:, size:)).blank?

      (errors[id] ||= []).concat(er)
    end

    def match_preview_info(filename, dav_info, md5:, size:)
      [].tap do |errors|
        errors << "#{filename} size mismatch" if size != dav_info.size
        errors << "#{filename} etag mismatch" if md5 != dav_info.etag
      end
    end
  end
end
