json.array!(@rubrics) do |rubric|
  # json.(rubric, :id, :rubric_id, :name)

  json.id rubric.id
  json.text rubric.name

  # FIXME: counter
  json.children true
end
