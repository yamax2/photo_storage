# frozen_string_literal: true

json.array!(@tracks) do |track|
  json.(track, :id, :color)

  json.url track.proxy_url
  json.name t(
    '.name', name: track.name, avg_speed: track.avg_speed, distance: track.distance, duration: track.duration
  )
end
