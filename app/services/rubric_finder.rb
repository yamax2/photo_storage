class RubricFinder
  def initialize(id)
    @id = id
  end

  def call
    raise ActiveRecord::RecordNotFound, "rubric #{@id} not found" unless rubrics.present?

    preload_rubric(rubrics.values.first)
  end

  def self.call(id)
    new(id).call
  end

  private

  # https://gist.github.com/sobstel/19f40ac2141cc1db0803d360127b2945
  def preload_rubric(rubric)
    return rubric unless rubric.rubric_id.present?

    association = rubric.association(:rubric)
    record = preload_rubric(rubrics.fetch(rubric.rubric_id))

    association.target = record
    association.set_inverse_instance(record)

    rubric
  end

  def rubrics
    @rubrics ||= Rubric.find_by_sql(<<~SQL).index_by(&:id)
      WITH RECURSIVE tt AS (
      SELECT id, rubric_id, 0 lv FROM rubrics WHERE id = #{@id}
      UNION ALL
      SELECT rubrics.id, rubrics.rubric_id, tt.lv + 1
        FROM rubrics, tt
          WHERE rubrics.id = tt.rubric_id)
      SELECT rubrics.* from rubrics, tt
        WHERE tt.id = rubrics.id
          ORDER BY tt.lv
    SQL
  end
end
