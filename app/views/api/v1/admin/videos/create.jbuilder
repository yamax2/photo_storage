# frozen_string_literal: true

if @video.valid? && @video.persisted?
  json.id @video.id
elsif @video.video?
  @video.errors.each do |error|
    json.set! error.attribute, error.message
  end
else
  json.content_type 'not a video'
end
