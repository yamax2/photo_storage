# frozen_string_literal: true

namespace :migrations do
  desc 'fill finished_at for tracks'
  # HOST=photos.tretyakov-ma.ru PROTOCOL=https bundle exec rails migrations:fill_tracks_finished_at
  task fill_tracks_finished_at: :environment do
    host = Rails.application.routes.default_url_options[:host]
    protocol = Rails.application.routes.default_url_options[:protocol]

    Track.
      uploaded.
      where(finished_at: nil).
      order(:id).
      each_instance(with_hold: true, block_size: 10) do |track|
      url = "#{protocol}://#{host}#{::ProxyUrls::Track.new(track).generate}"

      # rubocop:disable Security/Open
      tempfile = URI.open(url)
      # rubocop:enable Security/Open
      begin
        gpx = GPX::GPXFile.new(gpx_file: tempfile.path)
        finished_at = gpx.tracks.map { |item| item.points.map(&:time).compact.max }.max

        track.update!(finished_at: finished_at)
      ensure
        tempfile.try(:close)
        tempfile.try(:unlink)
      end
    end
  end

  desc 'fix duration for all tracks'
  task fix_tracks_duration: :environment do
    host = Rails.application.routes.default_url_options[:host]
    protocol = Rails.application.routes.default_url_options[:protocol]

    Track.uploaded.order(:id).each_instance(with_hold: true, block_size: 10) do |track|
      url = "#{protocol}://#{host}#{::ProxyUrls::Track.new(track).generate}"

      # rubocop:disable Security/Open
      tempfile = URI.open(url)
      # rubocop:enable Security/Open
      begin
        gpx = GPX::GPXFile.new(gpx_file: tempfile.path)

        old_value = track.duration
        track.update!(duration: gpx.moving_duration)

        Rails.logger.info "track #{track.id} updated from #{old_value} to #{track.duration}"
      rescue => e
        Rails.logger.error("#{track.id}: #{e.message}")
      ensure
        tempfile.try(:close)
        tempfile.try(:unlink)
      end
    end
  end
end
