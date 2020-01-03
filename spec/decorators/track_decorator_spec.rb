# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrackDecorator do
  describe 'info methods' do
    let(:track) do
      create(
        :track, avg_speed: 10.0 / 3, distance: 20.0 / 3, local_filename: 'test'
      ).decorate
    end

    it do
      expect(track.avg_speed).to eq(3.33)
      expect(track.distance).to eq(6.67)
    end
  end

  describe '#duration' do
    let(:track) { build(:track, duration: duration, local_filename: 'test').decorate }

    subject { track.duration }

    context 'when without hours' do
      let(:duration) { 59.minutes + 29.seconds }

      it { is_expected.to eq('59мин.') }
    end

    context 'when hours and minutes' do
      let(:duration) { 2.hours + 59.minutes + 29.seconds }

      it { is_expected.to eq('2ч. 59мин.') }
    end

    context 'when round up' do
      let(:duration) { 2.hours + 59.minutes + 39.seconds }

      it { is_expected.to eq('3ч.') }
    end

    context 'when zero minutes' do
      let(:duration) { 10.hours }

      it { is_expected.to eq('10ч.') }
    end

    context 'when zero' do
      let(:duration) { 28.seconds }

      it { is_expected.to eq('0') }
    end

    context 'when minutes < 10' do
      let(:duration) { 1.hour + 5.minutes + 59.seconds }

      it { is_expected.to eq('1ч. 06мин.') }
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
