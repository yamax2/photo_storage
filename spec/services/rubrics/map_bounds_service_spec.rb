# frozen_string_literal: true

RSpec.describe Rubrics::MapBoundsService do
  subject(:bounds) { described_class.call!(rubric_id: rubric.id).bounds }

  let(:rubric) { create :rubric }

  context 'when rubric without uploaded tracks and photos' do
    before do
      create :photo, rubric: rubric, local_filename: 'test.jpg', lat_long: [1, 2]
      create :track, rubric: rubric, local_filename: 'test.gpx'
    end

    it do
      expect(rubric.photos.size).to eq(1)
      expect(rubric.tracks.size).to eq(1)

      expect(bounds).to be_nil
    end
  end

  context 'when tracks and photos' do
    let(:token) { create :'yandex/token' }

    before do
      create :photo, rubric: rubric, storage_filename: 'test.jpg', lat_long: [1, 2], yandex_token: token
      create :photo, rubric: rubric, storage_filename: 'test.jpg', lat_long: [0, 1], yandex_token: token
      create :track, rubric: rubric, storage_filename: 'test.gpx', yandex_token: token
      create :track, rubric: rubric, storage_filename: 'test.gpx', yandex_token: token
    end

    it do
      expect(bounds).to eq(min_lat: 0.0, min_long: 1.0, max_lat: 3.0, max_long: 4.0)
    end
  end
end
