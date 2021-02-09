# frozen_string_literal: true

module Rubrics
  class TracksSummaryService
    TracksSummary = Struct.new(
      :avg_speed,
      :duration,
      :distance,
      :started_at,
      :finished_at,
      :real_duration
    )

    def initialize(rubric_id)
      @rubric_id = rubric_id
    end

    def call
      table = Track.arel_table

      data = Track.
        where(rubric_id: @rubric_id).
        pick(table[:duration].sum, table[:distance].sum, table[:started_at].minimum, table[:finished_at].maximum)

      summary_for(data) unless data.compact.empty?
    end

    private

    def summary_for(data)
      TracksSummary.new(
        (data[1] / (data[0] / 3600)).to_f,
        data[0].to_f,
        data[1].to_f,
        data[2],
        data[3]
      )
    end
  end
end
