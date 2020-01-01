# frozen_string_literal: true

json.array!(@tracks) do |track|
  json.(track, :id, :name, :avg_speed, :distance, :duration, :url)
end
