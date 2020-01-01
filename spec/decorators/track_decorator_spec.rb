# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrackDecorator do
  describe 'info methods' do
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

  describe '#proxy_url' do
    let(:track) { create(:track, local_filename: 'test').decorate }

    it do
      expect(track.proxy_url).to eq('http://proxy.photostorage.localhost')
    end
  end

  describe '#url' do
    subject { track.decorate.url }

    context 'when track is not uploaded' do
      let(:track) { create :track, local_filename: 'test' }

      it { is_expected.to be_nil }
    end

    context 'when track is uploaded' do
      let(:token) { create :'yandex/token', other_dir: '/other' }
      let(:track) { create :track, storage_filename: 'test.gpx', yandex_token: token, original_filename: 'my.gpx' }

      it do
        is_expected.to eq("http://proxy.photostorage.localhost/originals/other/test.gpx?fn=my.gpx&id=#{token.id}")
      end
    end
  end
end
