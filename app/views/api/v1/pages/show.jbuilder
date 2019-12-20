# frozen_string_literal: true

json.array!(@page.photos) do |photo|
  json.(photo, :id, :image_size, :name, :rn)

  json.url page_photo_path(@page.rubric, photo)
  json.preview photo.url(:thumb)
end
