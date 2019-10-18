# frozen_string_literal: true

json.array!(@rubrics) do |rubric|
  json.id rubric.id
  json.text "#{rubric.name} [#{selected_rubric_ids.fetch(rubric.id)}]"
  json.children rubric.rubrics_count.positive? && (rubric.rubrics.with_photos.pluck(:id) & selected_rubric_ids.keys).any?
end
