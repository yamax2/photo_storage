# frozen_string_literal: true

json.array!(@photos) do |photo|
  json.(photo, :id, :image_size, :name, :rn, :lat_long)

  json.url page_photo_path(photo.rubric_id, photo)
  json.preview photo.url(:thumb)
end
