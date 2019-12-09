# frozen_string_literal: true

module Tracks
  class ProcessFileJob
    include Sidekiq::Worker

    def perform(track_id)
      track = Track.find(track_id)

      Tracks::Process.call!(track: track)
    end
  end
end
