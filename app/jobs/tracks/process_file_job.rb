# frozen_string_literal: true

module Tracks
  class ProcessFileJob
    include Sidekiq::Worker

    def perform(track_id, new_storage_filename)
      track = Track.find(track_id)

      Tracks::Process.call!(
        track:,
        storage_filename: new_storage_filename
      )
    end
  end
end
