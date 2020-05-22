# frozen_string_literal: true

require 'rails_helper'

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
    let!(:photo) { create :photo, yandex_token: token, storage_filename: 'test' }
    let!(:track) { create :track, yandex_token: token, local_filename: 'test' }

    it do
      expect(token.photos).to match_array([photo])
      expect(token.tracks).to match_array([track])

      expect(result).to match_array([token])

      expect(result.first.photos_present).to eq(true)
      expect(result.first.other_present).to eq(false)
    end
  end

  context 'when only track is published' do
    let!(:photo) { create :photo, yandex_token: token, local_filename: 'test' }
    let!(:track) { create :track, yandex_token: token, storage_filename: 'test' }

    it do
      expect(token.photos).to match_array([photo])
      expect(token.tracks).to match_array([track])

      expect(result).to match_array([token])

      expect(result.first.photos_present).to eq(false)
      expect(result.first.other_present).to eq(true)
    end
  end

  context 'when both track and photo is published' do
    let!(:photo) { create :photo, yandex_token: token, storage_filename: 'test' }
    let!(:track) { create :track, yandex_token: token, storage_filename: 'test' }

    it do
      expect(token.photos).to match_array([photo])
      expect(token.tracks).to match_array([track])

      expect(result).to match_array([token])

      expect(result.first.photos_present).to eq(true)
      expect(result.first.other_present).to eq(true)
    end
  end

  context 'when some published resources for other_token exist' do
    before do
      create :photo, yandex_token: token, storage_filename: 'test'
      create :track, yandex_token: other_token, storage_filename: 'test'
    end

    it do
      expect(result).to eq([token, other_token])

      expect(result.first.photos_present).to eq(true)
      expect(result.first.other_present).to eq(false)

      expect(result.last.photos_present).to eq(false)
      expect(result.last.other_present).to eq(true)
    end
  end
end
