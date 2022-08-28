# frozen_string_literal: true

RSpec.describe Videos::MoveOriginalService do
  let(:node) { create :'yandex/token', access_token: API_ACCESS_TOKEN, other_dir: '/other_dev' }

  context 'when video exists' do
    subject(:move!) do
      VCR.use_cassette('video_move_success') do
        described_class.new(video, '/12.mp4').call

        YandexClient::Dav[API_ACCESS_TOKEN].propfind('/other_dev5')
      end
    end

    let(:video) { create :photo, :video, storage_filename: 'test1.mp4', yandex_token: node, folder_index: 5 }
    let(:moved_file) { move!.select(&:file?).find { |file| file.name == '/other_dev5/test1.mp4' } }

    it do
      expect { move! }.not_to raise_error

      expect(moved_file).not_to be_nil
    end
  end

  context 'when wrong temporary name' do
    subject(:move!) do
      VCR.use_cassette('video_move_failed_not_exists') { described_class.new(video, '/13.mp4').call }
    end

    let(:video) { create :photo, :video, storage_filename: 'test1.mp4', yandex_token: node }

    it do
      expect { move! }.to raise_error(YandexClient::NotFoundError)
    end
  end

  context 'when dest file already exists' do
    subject(:move!) do
      VCR.use_cassette('video_move_failed_duplicate') { described_class.new(video, '/12.mp4').call }
    end

    let(:video) do
      create :photo, :video, storage_filename: 'video4fbae93516ef627ee23a5269cb9277932e48e2c3.mp4', yandex_token: node
    end

    it do
      expect { move! }.to raise_error(YandexClient::ApiRequestError)
    end
  end
end
