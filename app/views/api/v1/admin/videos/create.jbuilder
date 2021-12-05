# frozen_string_literal: true

if @info
  json.id          @video.id
  json.upload_info @info
elsif @video.video?
  @video.errors.each do |error|
    json.set! error.attribute, error.message
  end
else
  json.content_type 'not a video'
end
