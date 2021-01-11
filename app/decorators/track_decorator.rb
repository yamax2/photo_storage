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

  def proxy_url
    url_generator.generate
  end

  private

  def format_duration(hours, minutes)
    result = []

    result << I18n.t('tracks.duration.hours', hours: hours) if hours.positive?
    result << I18n.t('tracks.duration.minutes', minutes: minutes.to_s.rjust(2, '0')) if minutes.positive?

    result.empty? ? '0' : result.join(' ')
  end

  def url_generator
    @url_generator ||= ::ProxyUrls::Track.new(object)
  end
end
