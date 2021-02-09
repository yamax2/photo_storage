# frozen_string_literal: true

RSpec.describe TrackDecorator do
  describe 'info methods' do
    let(:track) { create(:track, duration: 7_200, distance: 20.0 / 3, local_filename: 'test').decorate }

    it do
      expect(track.avg_speed).to eq(3.33)
      expect(track.distance).to eq(6.67)
    end
  end

  describe '#duration' do
    let(:track) { build(:track, duration: 7_200).decorate }

    it do
      expect(track.duration).to eq('2ч.')
    end
  end

  describe '#proxy_url' do
    subject(:url) { track.decorate.proxy_url }

    let(:token) { create :'yandex/token', other_dir: '/other' }
    let(:track) { create :track, storage_filename: 'test.gpx', yandex_token: token, original_filename: 'my.gpx' }

    it { is_expected.to eq("/proxy/other/test.gpx?fn=my.gpx&id=#{token.id}") }
  end
end
