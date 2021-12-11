# frozen_string_literal: true

RSpec.describe Videos::MoveOriginalJob do
  let(:node) { create :'yandex/token', access_token: API_ACCESS_TOKEN, other_dir: '/other_dev' }

  context 'when video exists' do
    subject(:move!) do
      VCR.use_cassette('video_move_success') do
        described_class.new.perform(video.id, '/12.mp4')

        YandexClient::Dav[API_ACCESS_TOKEN].propfind(node.other_dir)
      end
    end

    let(:video) { create :photo, :video, storage_filename: 'test1.mp4', yandex_token: node }
    let(:moved_file) { move!.select(&:file?).find { |file| file.name == '/other_dev/test1.mp4' } }

    it do
      expect { move! }.not_to raise_error

      expect(moved_file).not_to be_nil
    end
  end

  context 'when video does not exist' do
    it do
      expect { described_class.new.perform(1, 'test') }.
        to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when wrong temporary name' do
    subject(:move!) do
      VCR.use_cassette('video_move_failed_not_exists') { described_class.new.perform(video.id, '/13.mp4') }
    end

    let(:video) { create :photo, :video, storage_filename: 'test1.mp4', yandex_token: node }

    it do
      expect { move! }.to raise_error(YandexClient::NotFoundError)
    end
  end

  context 'when dest file already exists' do
    subject(:move!) do
      VCR.use_cassette('video_move_failed_duplicate') { described_class.new.perform(video.id, '/12.mp4') }
    end

    let(:video) do
      create :photo, :video, storage_filename: 'video0bd5626d12500a44c4cb5818a7ef73591a286dfc.mp4', yandex_token: node
    end

    it do
      expect { move! }.to raise_error(YandexClient::ApiRequestError)
    end
  end
end
