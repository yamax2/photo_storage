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
        other_count: nil,
        photo_size: 10.0,
        other_size: nil
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
        other_count: 1.0,
        photo_size: nil,
        other_size: 12.0
      )
    end
  end

  context 'when track, photo and video are published' do
    let!(:photo) { create :photo, yandex_token: token, storage_filename: 'test', size: 12 }
    let!(:track) { create :track, yandex_token: token, storage_filename: 'test', size: 10 }
    let!(:video) do
      create :photo,
             :video,
             yandex_token: token,
             storage_filename: 'test',
             size: 500,
             preview_size: 200,
             video_preview_size: 300
    end

    it do
      expect(token.photos).to match_array([photo, video])
      expect(token.tracks).to match_array([track])

      expect(result).to match_array([token])

      expect(result.first).to have_attributes(
        photo_count: 1,
        other_count: 4,
        photo_size: 12.0,
        other_size: 1_010.0
      )
    end
  end

  context 'when some published resources for other_token exist' do
    before do
      create :photo, yandex_token: token, storage_filename: 'test', size: 12
      create :track, yandex_token: other_token, storage_filename: 'test', size: 10

      create :photo,
             :video,
             yandex_token: other_token,
             size: 100,
             storage_filename: 'test',
             preview_size: 50,
             video_preview_size: 200
    end

    it do
      expect(result).to eq([token, other_token])

      expect(result.first).to have_attributes(
        photo_count: 1.0,
        other_count: nil,
        photo_size: 12.0,
        other_size: nil
      )

      expect(result.last).to have_attributes(
        photo_count: nil,
        other_count: 4,
        photo_size: nil,
        other_size: 360
      )
    end
  end

  context 'when some published resources with different folder_index' do
    before do
      create :photo, yandex_token: token, storage_filename: 'test', size: 12
      create :photo, yandex_token: token, storage_filename: 'test', size: 20, folder_index: 1

      create :track, yandex_token: other_token, storage_filename: 'test', size: 10

      create :photo,
             :video,
             yandex_token: token,
             storage_filename: 'test',
             size: 500,
             preview_size: 200,
             video_preview_size: 300,
             folder_index: 1
    end

    it do
      expect(result.to_a.size).to eq(3)

      expect(result.first).to have_attributes(
        id: token.id,
        folder_index: 0,
        photo_count: 1.0,
        photo_size: 12,
        other_count: nil,
        other_size: nil
      )

      expect(result.second).to have_attributes(
        id: token.id,
        folder_index: 1,
        photo_size: 20.0,
        photo_count: 1.0,
        other_size: 1000.0,
        other_count: 3.0
      )

      expect(result.last).to have_attributes(
        id: other_token.id,
        folder_index: 0,
        photo_size: nil,
        photo_count: nil,
        other_size: 10.0,
        other_count: 1.0
      )
    end
  end
end
