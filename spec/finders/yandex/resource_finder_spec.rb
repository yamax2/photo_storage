# frozen_string_literal: true

RSpec.describe Yandex::ResourceFinder do
  subject(:result) { described_class.call }

  let!(:token) { create :'yandex/token' }
  let!(:other_token) { create :'yandex/token' }

  context 'when without photos and tracks' do
    it { expect(result).to be_empty }
  end

  context 'when all resources are unpublished' do
    let!(:photo) { create :photo, yandex_token: token, local_filename: 'test' }
    let!(:track) { create :track, yandex_token: token, local_filename: 'test' }

    it do
      expect(token.photos).to match_array([photo])
      expect(token.tracks).to match_array([track])

      expect(result).to be_empty
    end
  end

  context 'when only photo is published' do
    let!(:photo) { create :photo, yandex_token: token, storage_filename: 'test', size: 10 }
    let!(:track) { create :track, yandex_token: token, local_filename: 'test', size: 12 }

    it do
      expect(token.photos).to match_array([photo])
      expect(token.tracks).to match_array([track])

      expect(result).to match_array([token])

      expect(result.first).to have_attributes(
        photo_count: 1.0,
        track_count: nil,
        photo_size: 10.0,
        track_size: nil
      )
    end
  end

  context 'when only track is published' do
    let!(:photo) { create :photo, yandex_token: token, local_filename: 'test', size: 10 }
    let!(:track) { create :track, yandex_token: token, storage_filename: 'test', size: 12 }

    it do
      expect(token.photos).to match_array([photo])
      expect(token.tracks).to match_array([track])

      expect(result).to match_array([token])

      expect(result.first).to have_attributes(
        photo_count: nil,
        track_count: 1.0,
        photo_size: nil,
        track_size: 12.0
      )
    end
  end

  context 'when both track and photo is published' do
    let!(:photo) { create :photo, yandex_token: token, storage_filename: 'test', size: 12 }
    let!(:track) { create :track, yandex_token: token, storage_filename: 'test', size: 10 }

    it do
      expect(token.photos).to match_array([photo])
      expect(token.tracks).to match_array([track])

      expect(result).to match_array([token])

      expect(result.first).to have_attributes(
        photo_count: 1.0,
        track_count: 1.0,
        photo_size: 12.0,
        track_size: 10.0
      )
    end
  end

  context 'when some published resources for other_token exist' do
    before do
      create :photo, yandex_token: token, storage_filename: 'test', size: 12
      create :track, yandex_token: other_token, storage_filename: 'test', size: 10
    end

    it do
      expect(result).to eq([token, other_token])

      expect(result.first).to have_attributes(
        photo_count: 1.0,
        track_count: nil,
        photo_size: 12.0,
        track_size: nil
      )

      expect(result.last).to have_attributes(
        photo_count: nil,
        track_count: 1.0,
        photo_size: nil,
        track_size: 10.0
      )
    end
  end
end
