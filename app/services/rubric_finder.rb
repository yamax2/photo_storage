# frozen_string_literal: true

# rubric with all loaded parents
class RubricFinder
  def initialize(id)
    @id = id
  end

  def call
    raise ActiveRecord::RecordNotFound, "rubric #{@id} not found" unless rubrics_by_id.present?

    preload_rubric(rubrics_by_id.values.first)
  end

  def self.call(id)
    new(id).call
  end

  private

  # https://gist.github.com/sobstel/19f40ac2141cc1db0803d360127b2945
  def preload_rubric(rubric)
    return rubric unless rubric.rubric_id.present?

    association = rubric.association(:rubric)
    record = preload_rubric(rubrics_by_id.fetch(rubric.rubric_id))

    association.target = record
    association.set_inverse_instance(record)

    rubric
  end

  def rubrics_by_id
    @rubrics_by_id ||= Rubrics::ParentsFinder.call(@id).index_by(&:id)
  end
end
