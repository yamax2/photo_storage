# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrackDecorator do
  let(:track) do
    create(
      :track, avg_speed: 10.0 / 3,
              distance: 20.0 / 3,
              duration: 3600 * 199.0 / 111,
              local_filename: 'test'
    ).decorate
  end

  it do
    expect(track.avg_speed).to eq(3.33)
    expect(track.distance).to eq(6.67)
    expect(track.duration).to eq(1.79)
  end
end
