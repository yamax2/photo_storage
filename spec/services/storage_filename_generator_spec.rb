# frozen_string_literal: true

RSpec.describe StorageFilenameGenerator do
  before do
    allow(SecureRandom).to receive(:hex).and_return('test')
  end

  context 'when photo partition mode' do
    let(:photo) { build_stubbed(:photo, id:, original_filename: '1.jpg') }
    let(:result) { described_class.new(photo).call }

    context 'when id = 1' do
      let(:id) { 1 }

      it do
        expect(result).to eq('000/000/1test.jpg')
      end
    end

    context 'when id = 499' do
      let(:id) { 499 }

      it do
        expect(result).to eq('000/000/499test.jpg')
      end
    end

    context 'when id = 501' do
      let(:id) { 501 }

      it do
        expect(result).to eq('000/001/501test.jpg')
      end
    end

    context 'when id = 250_001' do
      let(:id) { 250_001 }

      it do
        expect(result).to eq('001/000/250001test.jpg')
      end
    end

    context 'when id = 250_501' do
      let(:id) { 250_501 }

      it do
        expect(result).to eq('001/001/250501test.jpg')
      end
    end

    context 'when id = 500_000' do
      let(:id) { 500_000 }

      it do
        expect(result).to eq('002/000/500000test.jpg')
      end
    end

    context 'when id = 125_000_000' do
      let(:id) { 125_000_000 }

      it do
        expect { result }.to raise_error('fixme: 125000000')
      end
    end
  end

  context 'when track with disabled partition' do
    let(:track) { build_stubbed :track, local_filename: 'test.gpx' }

    it do
      expect(described_class.new(track, partition: false).call).to eq("#{track.id}test")
    end
  end

  context 'when video with a prefix' do
    let(:video) { build :photo, :video, original_filename: 'test.mp4' }

    it do
      expect(described_class.new(video, partition: false, prefix: :video).call).to eq('videotest.mp4')
    end
  end
end
