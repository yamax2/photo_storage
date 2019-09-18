module Rubrics
  # data - array of ids
  class ApplyOrder
    include ::Interactor

    delegate :data, :id, to: :context

    def call
      table_name = Rubric.quoted_table_name

      Rubric.connection.execute(<<~SQL)
        WITH ord as (#{build_ord_table}), result as (
          SELECT rubrics.id, ROW_NUMBER() OVER (ORDER BY ord.rn) rn
            FROM ord, #{table_name} rubrics
              WHERE rubrics.id = ord.id #{build_parent_condition}
        )
        UPDATE #{table_name} SET ord = result.rn
        FROM result
          WHERE rubrics.id = result.id
      SQL
    end

    private

    def build_ord_table
      data.
        uniq.
        each_with_index.
        each_with_object([]) { |(id, index), sql| sql << "SELECT #{id} id, #{index} rn" }.
        join(' UNION ALL ')
    end

    def build_parent_condition
      if id.to_i.positive?
        "AND rubrics.rubric_id = #{id}"
      else
        'AND rubrics.rubric_id IS NULL'
      end
    end
  end
end
