# frozen_string_literal: true

module Tracks
  class LoadInfoService
    include ::Interactor

    delegate :track, to: :context

    def call
      return unless track.local_file?

      track.update!(
        distance: gpx.distance,
        duration: gpx.duration,
        started_at: calc_time(:min),
        finished_at: calc_time(:max),
        bounds: bounds
      )
    end

    private

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

    def calc_time(method)
      gpx.tracks.map { |track| track.points.map(&:time).compact.public_send(method) }.public_send(method)
    end
  end
end
