# frozen_string_literal: true

RSpec.describe Yandex::ReviseOtherDirService do
  let(:token) { create :'yandex/token', other_dir: '/other_dev', access_token: API_ACCESS_TOKEN }
  let!(:video) do
    create :photo, :video, storage_filename: 'VID_20211104_121243.mp4',
                           preview_filename: 'VID_20211104_121243.mp4.jpg',
                           video_preview_filename: 'video4fbae93516ef627ee23a5269cb9277932e48e2c3.preview.mp4',
                           size: 60_518_940,
                           preview_size: 360_580,
                           video_preview_size: 6_958_704,
                           md5: '4c863a1f2f92740565a0bf0919598893',
                           preview_md5: 'ec22d5b206a64036b37a8d66c3e6a3c6',
                           video_preview_md5: 'c3ec1da49730da2d428ab2f986f3aac7',
                           yandex_token: token
  end

  let!(:track) do
    create :track, storage_filename: '7008ed91aa61caac19d80fc41a3d10b12466c2769cb.gpx',
                   size: 1_453_201,
                   md5: '95fbf34957defb9289714639ec96c657',
                   yandex_token: token
  end

  let!(:another_track) do
    create :track, storage_filename: '701ba1d236be9567ffc391f48c1d6830e2b5619fbb2.gpx',
                   size: 453_651,
                   md5: 'e831e882e09f099ad02f3cf8f7862454',
                   yandex_token: token,
                   folder_index: 1
  end

  let!(:another_video) do
    create :photo, :video, storage_filename: 'video49c1b012f21f77490971fc170b036dbbbf9c457c.mp4',
                           preview_filename: 'video49c1b012f21f77490971fc170b036dbbbf9c457c.mp4.jpg',
                           video_preview_filename: 'video49c1b012f21f77490971fc170b036dbbbf9c457c.preview.mp4',
                           size: 54_336_364,
                           preview_size: 250_977,
                           video_preview_size: 1_261_274,
                           md5: '1f21fcc757293c2df4cdb6485f9885ea',
                           preview_md5: 'c9743282c5742cb8d0c3910ada8d1f17',
                           video_preview_md5: '0fb60e3c9d186166b2bb6a2748239ac0',
                           yandex_token: token,
                           folder_index: 1
  end

  before do
    create :track, local_filename: 'test'

    create :track, storage_filename: '69853337f2a537d654b3f062af5ff939ea6d6a6358c.gpx',
                   size: 5_985_588,
                   md5: 'c8740b29d009bcc106733d0387e070b8',
                   yandex_token: token

    create :track, storage_filename: '6999074555a5624c001a8c20a3ff3e76a663b8070f0.gpx',
                   size: 773_092,
                   md5: 'a0c943c88f6a1640eacd5a741ce632b8',
                   yandex_token: token
  end

  context 'when dir does not exists' do
    subject(:service_context) do
      VCR.use_cassette('yandex_revise_others_wrong_dir') { described_class.call!(token:, folder_index: 0) }
    end

    let(:token) { create :'yandex/token', other_dir: '/other1', access_token: API_ACCESS_TOKEN }

    it do
      expect(service_context).to be_a_success

      expect(service_context.errors.keys).to eq([nil])
      expect(service_context.errors[nil]).to eq(['dir /other1 not found on remote storage'])
    end
  end

  context 'when dir exists' do
    subject(:service_context) do
      VCR.use_cassette('yandex_revise_other_dir') { described_class.call!(token:, folder_index: 0) }
    end

    context 'when track does not exist in database' do
      let!(:track) { nil }

      it do
        expect(track).to be_nil
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq([nil])
        expect(service_context.errors[nil]).to eq(['7008ed91aa61caac19d80fc41a3d10b12466c2769cb.gpx'])
      end
    end

    context 'when track does not exist on remote storage' do
      let!(:track4) { create :track, storage_filename: 'test.gpx', yandex_token: token }

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq(["track:#{track4.id}"])
        expect(service_context.errors["track:#{track4.id}"]).to eq(['not found on the remote storage'])
      end
    end

    context 'when wrong track info' do
      let!(:track) do
        create :track, storage_filename: '7008ed91aa61caac19d80fc41a3d10b12466c2769cb.gpx',
                       size: 3_780_954,
                       md5: 'a568fedd7b0b3224611a3e29a9127c22',
                       yandex_token: token
      end

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq(["track:#{track.id}"])
        expect(service_context.errors["track:#{track.id}"]).to contain_exactly('size mismatch', 'etag mismatch')
      end
    end

    context 'when video does not exist on remote storage' do
      let!(:video1) { create :photo, :video, storage_filename: 'test.mp4', yandex_token: token }

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq(["photo:#{video1.id}"])
        expect(service_context.errors["photo:#{video1.id}"]).to contain_exactly(
          'not found on the remote storage',
          'test.mp4.jpg not found on the remote storage',
          'test.preview.mp4 not found on the remote storage'
        )
      end
    end

    context 'when video does not exist in database' do
      let!(:video) { nil }

      it do
        expect(video).to be_nil
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq([nil])
        expect(service_context.errors[nil]).to match_array(
          %w[
            VID_20211104_121243.mp4
            VID_20211104_121243.mp4.jpg
            video4fbae93516ef627ee23a5269cb9277932e48e2c3.preview.mp4
          ]
        )
      end
    end

    context 'when wrong video info' do
      let!(:video) do
        create :photo, :video, storage_filename: 'VID_20211104_121243.mp4',
                               preview_filename: 'VID_20211104_121243.mp4.jpg',
                               video_preview_filename: 'video4fbae93516ef627ee23a5269cb9277932e48e2c3.preview.mp4',
                               size: 60_518_941,
                               preview_size: 360_581,
                               video_preview_size: 6_958_701,
                               md5: '4c863a1f2f92740565a0bf0919598891',
                               preview_md5: 'ec22d5b206a64036b37a8d66c3e6a3c5',
                               video_preview_md5: 'c3ec1da49730da2d428ab2f986f3aac8',
                               yandex_token: token
      end

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq(["photo:#{video.id}"])
        expect(service_context.errors["photo:#{video.id}"]).to contain_exactly(
          'size mismatch',
          'etag mismatch',
          'VID_20211104_121243.mp4.jpg size mismatch',
          'VID_20211104_121243.mp4.jpg etag mismatch',
          'video4fbae93516ef627ee23a5269cb9277932e48e2c3.preview.mp4 size mismatch',
          'video4fbae93516ef627ee23a5269cb9277932e48e2c3.preview.mp4 etag mismatch'
        )
      end
    end

    context 'when preview for a video does not exist on a remote storage' do
      let!(:video) do
        create :photo, :video, storage_filename: 'VID_20211104_121243.mp4',
                               preview_filename: 'VID_20211104_121243.mp4.jpeg',
                               video_preview_filename: 'video4fbae93516ef627ee23a5269cb9277932e48e2c3.preview.mp4',
                               size: 60_518_940,
                               preview_size: 360_580,
                               video_preview_size: 6_958_704,
                               md5: '4c863a1f2f92740565a0bf0919598893',
                               preview_md5: 'ec22d5b206a64036b37a8d66c3e6a3c6',
                               video_preview_md5: 'c3ec1da49730da2d428ab2f986f3aac7',
                               yandex_token: token
      end

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq(["photo:#{video.id}", nil])
        expect(service_context.errors["photo:#{video.id}"]).
          to contain_exactly('VID_20211104_121243.mp4.jpeg not found on the remote storage')
        expect(service_context.errors[nil]).to match_array(%w[VID_20211104_121243.mp4.jpg])
      end
    end

    context 'when video preview does not exist on a remote storage' do
      let!(:video) do
        create :photo, :video, storage_filename: 'VID_20211104_121243.mp4',
                               preview_filename: 'VID_20211104_121243.mp4.jpg',
                               video_preview_filename: '1.preview.mp4',
                               size: 60_518_940,
                               preview_size: 360_580,
                               video_preview_size: 6_958_704,
                               md5: '4c863a1f2f92740565a0bf0919598893',
                               preview_md5: 'ec22d5b206a64036b37a8d66c3e6a3c6',
                               video_preview_md5: 'c3ec1da49730da2d428ab2f986f3aac7',
                               yandex_token: token
      end

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq(["photo:#{video.id}", nil])
        expect(service_context.errors["photo:#{video.id}"]).
          to contain_exactly('1.preview.mp4 not found on the remote storage')
        expect(service_context.errors[nil]).
          to match_array(%w[video4fbae93516ef627ee23a5269cb9277932e48e2c3.preview.mp4])
      end
    end

    context 'when without errors' do
      it do
        expect(service_context).to be_a_success
        expect(service_context.errors).to be_empty
      end
    end
  end

  context 'when folder_index is greater than zero' do
    subject(:service_context) do
      VCR.use_cassette('yandex_revise_other_dir_folder_index') { described_class.call!(token:, folder_index: 1) }
    end

    context 'when without errors' do
      it do
        expect(another_video).not_to be_nil

        expect(service_context).to be_a_success
        expect(service_context.errors).to be_empty
      end
    end

    context 'when track does not exist' do
      let!(:another_track) { nil }

      it do
        expect(service_context).to be_a_success
        expect(another_track).to be_nil

        expect(service_context.errors.keys).to eq([nil])
        expect(service_context.errors[nil]).to eq(['701ba1d236be9567ffc391f48c1d6830e2b5619fbb2.gpx'])
      end
    end
  end
end
