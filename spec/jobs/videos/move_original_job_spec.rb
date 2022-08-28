# frozen_string_literal: true

RSpec.describe Videos::MoveOriginalJob do
  context 'when wrong video' do
    it do
      expect { described_class.new.perform(4, '12.mp4') }.
        to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when correct video' do
    subject(:perform!) do
      VCR.use_cassette('video_move_success') do
        described_class.new.perform(video.id, '/12.mp4')

        YandexClient::Dav[API_ACCESS_TOKEN].propfind('/other_dev5')
      end
    end

    let(:node) { create :'yandex/token', access_token: API_ACCESS_TOKEN, other_dir: '/other_dev' }
    let(:video) { create :photo, :video, storage_filename: 'test1.mp4', yandex_token: node, folder_index: 5 }
    let(:moved_file) { perform!.select(&:file?).find { |file| file.name == '/other_dev5/test1.mp4' } }

    it do
      expect { perform! }.not_to raise_error

      expect(moved_file).not_to be_nil
    end
  end
end
