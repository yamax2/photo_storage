# frozen_string_literal: true

RSpec.describe Yandex::ReviseDirService do
  let(:dir) { '000/013/' }
  let(:token) { create :'yandex/token', dir: '/test', access_token: API_ACCESS_TOKEN }

  before do
    create :photo, local_filename: 'test'

    create :photo, storage_filename: '000/013/651499c8340faf3e270de72ffe652df55855697eed5b.jpg',
                   size: 2_227_965,
                   md5: '7a9fcf31e891422947b3f67b9d15208f',
                   content_type: 'image/jpeg',
                   yandex_token: token

    create :photo, storage_filename: '000/013/65156d3a0a5428ca01a374c72c3488db6a9b95b77c2f.jpg',
                   size: 6_651_603,
                   md5: '98d63be6348659f5d3623246a55fcb39',
                   content_type: 'image/jpeg',
                   yandex_token: token

    create :photo, :video, yandex_token: token, storage_filename: '000/013/test.mov'

    create :photo, storage_filename: '000/002/1447d9f01a2e115584cf14012598f5127267056671b0.jpg',
                   size: 8_045_765,
                   md5: '2ccaae012e1ca67a61beb6f36797fd93',
                   content_type: 'image/jpeg',
                   yandex_token: token,
                   folder_index: 1
  end

  context 'when dir exists' do
    subject(:service_context) do
      VCR.use_cassette('yandex_revise_dir') { described_class.call!(dir:, token:, folder_index: 0) }
    end

    context 'when photo does not exist in database' do
      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq([nil])
        expect(service_context.errors[nil]).to eq(['000/013/6516fdedf98ba516916be55f04faeec88d14718325dc.jpg'])
      end
    end

    context 'when photo does not exist on remote storage' do
      before do
        create :photo, storage_filename: '000/013/6516fdedf98ba516916be55f04faeec88d14718325dc.jpg',
                       size: 5_795_643,
                       md5: '635d4505b9dfd1b49ab346c8209e09f7',
                       content_type: 'image/jpeg',
                       yandex_token: token
      end

      let!(:photo4) { create :photo, storage_filename: '000/013/zzz.jpg', yandex_token: token }

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq(["photo:#{photo4.id}"])
        expect(service_context.errors["photo:#{photo4.id}"]).to eq(['not found on the remote storage'])
      end
    end

    context 'when wrong photo info' do
      let!(:photo3) do
        create :photo, storage_filename: '000/013/6516fdedf98ba516916be55f04faeec88d14718325dc.jpg',
                       size: 5_795_644,
                       md5: '635d4505b9dfd1b49ab346c8209e09f8',
                       content_type: 'image/png',
                       yandex_token: token
      end

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq(["photo:#{photo3.id}"])
        expect(service_context.errors["photo:#{photo3.id}"]).to contain_exactly(
          'size mismatch',
          'content type mismatch',
          'etag mismatch'
        )
      end
    end

    context 'when without errors' do
      before do
        create :photo, storage_filename: '000/013/6516fdedf98ba516916be55f04faeec88d14718325dc.jpg',
                       size: 5_795_643,
                       md5: '635d4505b9dfd1b49ab346c8209e09f7',
                       content_type: 'image/jpeg',
                       yandex_token: token
      end

      it do
        expect(service_context).to be_a_success
        expect(service_context.errors).to be_empty
      end
    end
  end

  context 'when folder_index is greater than zero' do
    subject(:service_context) do
      VCR.use_cassette('yandex_revise_dir_folder_index') { described_class.call!(dir:, token:, folder_index: 1) }
    end

    let(:dir) { '000/002/' }
    let(:token) { create :'yandex/token', dir: '/photos_dev', access_token: API_ACCESS_TOKEN }

    context 'when without errors' do
      it do
        expect(service_context).to be_a_success
        expect(service_context.errors).to be_empty
      end
    end

    context 'when photo does not exist on remote storage' do
      let!(:wrong_photo) do
        create :photo, storage_filename: '000/002/6516fdedf98ba516916be55f04faeec88d14718325dc.jpg',
                       size: 5_795_643,
                       md5: '635d4505b9dfd1b49ab346c8209e09f7',
                       content_type: 'image/jpeg',
                       yandex_token: token,
                       folder_index: 1
      end

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq(["photo:#{wrong_photo.id}"])
        expect(service_context.errors["photo:#{wrong_photo.id}"]).to eq(['not found on the remote storage'])
      end
    end
  end

  context 'when dir does not exist' do
    subject(:service_context) do
      VCR.use_cassette('yandex_revise_wrong_dir') { described_class.call!(dir:, token:, folder_index: 0) }
    end

    let(:dir) { '011/013/' }

    it do
      expect(service_context).to be_a_success

      expect(service_context.errors.keys).to eq([nil])
      expect(service_context.errors[nil]).to eq(['dir /test/011/013/ not found on remote storage'])
    end
  end
end
