# frozen_string_literal: true

json.array!(@photos) do |photo|
  json.(photo, :id, :image_size, :name, :rn, :lat_long)

  json.url page_photo_path(photo.rubric_id, photo)
  json.preview photo.url(:thumb)

  json.properties do
    json.rotated_deg photo.rotated_deg
    json.actual_image_size photo.image_size(apply_rotation: true)
  end
end
