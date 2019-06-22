json.array!(@rubrics) do |rubric|
  # json.(rubric, :id, :rubric_id, :name)

  json.id rubric.id
  json.text "#{rubric.name} (#{rubric.photos_count})"

  json.children rubric.rubrics_count.positive?
end
