# frozen_string_literal: true

json.array!(@rubrics) do |rubric|
  json.(rubric, :id)
  json.text "#{rubric.name} [#{selected_rubric_ids.fetch(rubric.id)}]"
  json.children children?(rubric)
end
