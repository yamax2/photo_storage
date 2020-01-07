# frozen_string_literal: true

module Tracks
  class LoadInfoService
    include ::Interactor

    delegate :track, to: :context

    def call
      return unless track.local_file?

      track.update!(
        distance: gpx.distance,
        avg_speed: avg_speed,
        duration: gpx.duration,
        started_at: started_at,
        bounds: bounds
      )
    end

    private

    def avg_speed
      if (avg_speed = gpx.average_speed).infinite?
        0
      else
        avg_speed
      end
    end

    def bounds
      data = gpx.bounds

      [
        ActiveRecord::Point.new(data.min_lat, data.min_lon),
        ActiveRecord::Point.new(data.max_lat, data.max_lon)
      ]
    end

    def gpx
      @gpx ||= GPX::GPXFile.new(gpx_file: track.tmp_local_filename.to_s)
    end

    def started_at
      gpx.tracks.map { |track| track.points.map(&:time).compact.min }.min
    end
  end
end
