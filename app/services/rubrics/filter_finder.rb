# frozen_string_literal: true

module Rubrics
  # filters rubrics by name
  class FilterFinder
    def initialize(name_part:)
      @name_part = name_part
    end

    def self.call(name_part:)
      new(name_part: name_part).call
    end

    def call
      return Rubric.all unless @name_part.present?

      table_name = Rubric.quoted_table_name

      Rubric.joins(<<~SQL)
        JOIN (
          WITH RECURSIVE filtered AS (
            SELECT id, rubric_id FROM #{table_name}
            WHERE name ILIKE #{Rubric.connection.quote("%#{@name_part}%")}
            UNION ALL
            SELECT rubrics.id, rubrics.rubric_id
              FROM #{table_name} rubrics, filtered
             WHERE rubrics.id = filtered.rubric_id
          )
          SELECT DISTINCT id FROM filtered
        ) filtered ON filtered.id = #{table_name}.id
      SQL
    end
  end
end
