# frozen_string_literal: true

if @success
  json.id @photo.id
else
  @photo.errors.each do |attr, value|
    json.set! attr, value
  end
end
