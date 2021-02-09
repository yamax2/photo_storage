# frozen_string_literal: true

class FillTrackCounter < ActiveRecord::Migration[6.1]
  def up
    return if Rails.env.test?

    execute <<~SQL.squish
      WITH source AS (
      SELECT rubric_id, COUNT(*) cc FROM tracks GROUP BY rubric_id
      )
      UPDATE rubrics
      SET tracks_count = source.cc
      FROM source
        WHERE rubrics.id = source.rubric_id
    SQL
  end

  def down
  end
end
