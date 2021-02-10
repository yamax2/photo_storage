# frozen_string_literal: true

module Formatters
  class Duration
    def initialize(value_seconds)
      @minutes = (value_seconds / 60.0).round
    end

    def call
      minutes = @minutes

      days = (minutes / (24 * 60)).floor
      minutes -= days * 24 * 60

      hours = (minutes / 60).floor
      minutes -= hours * 60

      format_duration_text days, hours, minutes
    end

    private

    def format_duration_text(days, hours, minutes)
      result = []

      result << I18n.t('tracks.duration.days', days: days) if days.positive?
      result << I18n.t('tracks.duration.hours', hours: hours) if hours.positive?
      result << I18n.t('tracks.duration.minutes', minutes: minutes.to_s.rjust(2, '0')) if minutes.positive?

      result.empty? ? '0' : result.join(' ')
    end
  end
end
