# frozen_string_literal: true

json.array!(@objects) do |obj|
  json.(obj, :id, :model_type, :lat_long)

  default_size = [480, 360]
  has_dimensions = obj.width && obj.height

  json.image_size has_dimensions ? obj.image_size : default_size
  json.preview obj.url(:thumb)

  name = obj.name

  if obj.rubric?
    name << t('rubrics.name.rubrics_count_text', rubrics_count: obj.rubrics_count) if obj.rubrics_count.positive?
    name << t('rubrics.name.photos_count_text', photos_count: obj.photos_count) if obj.photos_count.positive?

    json.url page_path(obj.id)
  else
    json.url page_photo_path(obj.rubric_id, obj.id)
  end

  json.name name
  json.properties do
    json.turned obj.turned?
    json.css_transform obj.css_transform
    json.actual_image_size has_dimensions ? obj.image_size(apply_rotation: true) : default_size
  end
end
