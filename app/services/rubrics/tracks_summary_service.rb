# frozen_string_literal: true

module Rubrics
  class TracksSummaryService
    Summary = Struct.new(
      :avg_speed,
      :duration,
      :distance,
      :started_at,
      :finished_at,
      :travel_duration
    )

    def initialize(rubric_id)
      @rubric_id = rubric_id
    end

    def call
      table = Track.arel_table
      data = Track.
        where(rubric_id: @rubric_id).
        pick(
          table[:duration].sum,
          table[:distance].sum,
          table[:started_at].minimum,
          table[:finished_at].maximum
        )

      summary_for(data) if data.compact.any?
    end

    private

    def summary_for(data) # rubocop:disable Metrics/AbcSize
      started_at, finished_at = data[2], data[3]

      Summary.new(
        format_num(data[1] / (data[0] / 3_600)), # avg_speed, km/h
        format_duration(data[0]),                # duration, text
        format_num(data[1]),                     # distance, km
        format_time(started_at),
        format_time(finished_at)
      ).tap do |summary|
        summary.travel_duration = format_duration(finished_at - started_at) if finished_at && started_at
      end
    end

    def format_duration(value)
      Formatters::Duration.new(value).call
    end

    def format_num(value)
      value.round(2).to_f
    end

    def format_time(value)
      value&.in_time_zone(Rails.application.config.time_zone)
    end
  end
end
