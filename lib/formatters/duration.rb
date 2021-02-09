# frozen_string_literal: true

module Formatters
  class Duration
    def initialize(value_seconds)
      @value = (value_seconds / 60.0).round
    end

    def call
      hours = (@value / 60).floor
      minutes = (@value - hours * 60).floor

      format_duration_text hours, minutes
    end

    private

    def format_duration_text(hours, minutes)
      result = []

      result << I18n.t('tracks.duration.hours', hours: hours) if hours.positive?
      result << I18n.t('tracks.duration.minutes', minutes: minutes.to_s.rjust(2, '0')) if minutes.positive?

      result.empty? ? '0' : result.join(' ')
    end
  end
end
