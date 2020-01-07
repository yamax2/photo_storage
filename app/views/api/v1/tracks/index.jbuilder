# frozen_string_literal: true

json.tracks do
  json.array!(@tracks) do |track|
    json.(track, :id, :color)

    json.name t(
      '.name', name: track.name, avg_speed: track.avg_speed, distance: track.distance, duration: track.duration
    )

    json.url "#{track.url}&session=#{current_session}"
  end
end

json.bounds @bounds
