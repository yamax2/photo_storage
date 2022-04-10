# frozen_string_literal: true

module Formatters
  class Duration
    def initialize(value_seconds, include_seconds: false)
      @minutes = (value_seconds / 60.0).round
      @seconds = (value_seconds % 60).round if include_seconds
    end

    def call
      minutes = @minutes

      days = (minutes / (24 * 60)).floor
      minutes -= days * 24 * 60

      hours = (minutes / 60).floor
      minutes -= hours * 60

      formatted = format_duration_text(days, hours, minutes, @seconds)

      formatted.empty? ? '0' : formatted.join(' ')
    end

    private

    def format_duration_text(days, hours, minutes, seconds)
      result = []

      result << I18n.t('tracks.duration.days', days:) if days.positive?
      result << I18n.t('tracks.duration.hours', hours:) if hours.positive?
      result << I18n.t('tracks.duration.minutes', minutes: minutes.to_s.rjust(2, '0')) if minutes.positive?
      result << I18n.t('tracks.duration.seconds', seconds: @seconds.to_s.rjust(2, '0')) if seconds&.positive?

      result
    end
  end
end
