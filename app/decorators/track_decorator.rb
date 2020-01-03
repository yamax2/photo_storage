# frozen_string_literal: true

class TrackDecorator < ApplicationDecorator
  delegate_all

  def avg_speed
    super.round(2)
  end

  def distance
    super.round(2)
  end

  def duration
    value = (super / 60).round

    hours = (value / 60).floor
    minutes = (value - hours * 60).floor

    format_duration(hours, minutes)
  end

  def url
    return if storage_filename.blank?

    [
      proxy_url,
      'originals',
      yandex_token.other_dir.sub(%r{^/}, ''),
      storage_filename
    ].join('/').tap do |url|
      url << "?fn=#{original_filename}"
      url << "&id=#{yandex_token_id}"
    end
  end

  private

  def format_duration(hours, minutes)
    result = []

    result << I18n.t('tracks.duration.hours', hours: hours) if hours.positive?
    result << I18n.t('tracks.duration.minutes', minutes: minutes.to_s.rjust(2, '0')) if minutes.positive?

    result.empty? ? '0' : result.join(' ')
  end
end
