# frozen_string_literal: true

module Yandex
  class ReviseJob
    include Sidekiq::Worker

    def perform
      revise_photos
      revise_tracks
    end

    private

    def revise_photos
      Photo.uploaded.select(
        :yandex_token_id,
        "regexp_replace(storage_filename, '[a-z0-9]+\.[A-z]+$', '') dir"
      ).distinct.each_row(
        with_hold: true,
        symbolize_keys: true,
        block_size: 10
      ) do |row|
        ReviseDirJob.perform_async(row[:dir], row[:yandex_token_id])
      end
    end

    def revise_tracks
      Track.uploaded.select(:yandex_token_id).distinct.each_row(
        with_hold: true,
        symbolize_keys: true,
        block_size: 10
      ) do |row|
        ReviseOtherDirJob.perform_async(row[:yandex_token_id])
      end
    end
  end
end
