# frozen_string_literal: true

module Tracks
  class LoadInfoService
    include ::Interactor

    delegate :track, to: :context

    def call
      return unless track.local_file?

      avg_speed = gpx.average_speed
      avg_speed = 0 if avg_speed.infinite?

      track.update!(
        distance: gpx.distance,
        avg_speed: avg_speed,
        duration: gpx.duration
      )
    end

    private

    def gpx
      @gpx ||= GPX::GPXFile.new(gpx_file: track.tmp_local_filename.to_s)
    end
  end
end
