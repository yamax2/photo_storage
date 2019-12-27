# frozen_string_literal: true

module Yandex
  class ReviseOtherDirService < BaseReviseService
    private

    def base_storage_dir
      token.other_dir
    end

    def relation_to_revise
      Track.uploaded.where(yandex_token: token)
    end
  end
end
