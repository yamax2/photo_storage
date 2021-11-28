# frozen_string_literal: true

json.array!(@listing) do |obj|
  json.(obj, :id, :name, :model_type, :lat_long, :image_size)
  json.preview obj.proxy_url

  if obj.rubric?
    json.url page_path(obj.id)
  else
    json.url page_photo_path(obj.rubric_id, obj.id)
  end

  json.properties do
    json.turned obj.turned?
    json.css_transform obj.css_transform
    json.actual_image_size obj.image_size(apply_rotation: true)
    json.video obj.video?
  end
end
