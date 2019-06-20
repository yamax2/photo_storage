json.array!(@rubrics) do |rubric|
  # json.(rubric, :id, :rubric_id, :name)

  json.id rubric.id
  json.text rubric.name

  json.children rubric.rubrics_count.positive?
end
