# frozen_string_literal: true

module Rubrics
  # finds rubric with all its parents ordered by level, returns relation
  class ParentsFinder
    def initialize(rubric_id)
      @rubric_id = rubric_id
    end

    def call
      table_name = Rubric.quoted_table_name

      Rubric.joins(<<~SQL).order(:lv)
        JOIN (
          WITH RECURSIVE tt AS (
            SELECT id, rubric_id, 0 lv FROM #{table_name}
              WHERE id = #{@rubric_id}
            UNION ALL
            SELECT rubrics.id, rubrics.rubric_id, tt.lv + 1
              FROM #{table_name} rubrics, tt
                WHERE rubrics.id = tt.rubric_id
          )
          SELECT tt.id, tt.lv FROM tt
        ) parents ON parents.id = #{table_name}.id
      SQL
    end

    def self.call(rubric_id)
      new(rubric_id).call
    end
  end
end
