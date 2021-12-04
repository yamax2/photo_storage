# frozen_string_literal: true

module Yandex
  class ReviseJob
    include Sidekiq::Worker

    def perform
      revise_photos
      revise_other
    end

    private

    def revise_photos
      Photo.images.uploaded.select(
        :yandex_token_id,
        "regexp_replace(storage_filename, '[a-z0-9]+\.[A-z]+$', '') dir"
      ).distinct.each_row(
        symbolize_keys: true,
        block_size: 10
      ) do |row|
        ReviseDirJob.perform_async(row[:dir], row[:yandex_token_id])
      end
    end

    def revise_other
      other_resources_nodes.each_row(
        symbolize_keys: true,
        block_size: 10
      ) do |row|
        ReviseOtherDirJob.
          perform_async(row[:yandex_token_id])
      end
    end

    def other_resources_nodes
      Yandex::Token.distinct.select(:yandex_token_id).from(
        Arel::Nodes::Union.new(
          Track.uploaded.select(:yandex_token_id).arel,
          Photo.videos.select(:yandex_token_id).arel
        ).as('nodes')
      )
    end
  end
end
