require 'rails_helper'

RSpec.describe Yandex::ReviseDirService do
  let(:dir) { '000/013/' }
  let(:token) { create :'yandex/token', dir: '/test', access_token: API_ACCESS_TOKEN }

  let!(:unpublished_photo) { create :photo, :fake, local_filename: 'test' }

  let!(:photo1) do
    create :photo, :fake, storage_filename: '000/013/651499c8340faf3e270de72ffe652df55855697eed5b.jpg',
                          size: 2_227_965,
                          md5: '7a9fcf31e891422947b3f67b9d15208f',
                          content_type: 'image/jpeg',
                          yandex_token: token
  end

  let!(:photo2) do
    create :photo, :fake, storage_filename: '000/013/65156d3a0a5428ca01a374c72c3488db6a9b95b77c2f.jpg',
                          size: 6_651_603,
                          md5: '98d63be6348659f5d3623246a55fcb39',
                          content_type: 'image/jpeg',
                          yandex_token: token
  end

  subject do
    VCR.use_cassette('yandex_revise_dir') { described_class.call!(dir: dir, token: token) }
  end

  context 'when photo does not exist in database' do
    it do
      is_expected.to be_a_success

      expect(subject.errors.keys).to eq([nil])
      expect(subject.errors[nil]).to eq(['000/013/6516fdedf98ba516916be55f04faeec88d14718325dc.jpg'])
    end
  end

  context 'when photo does not exist on remote storage' do
    let!(:photo3) do
      create :photo, :fake, storage_filename: '000/013/6516fdedf98ba516916be55f04faeec88d14718325dc.jpg',
                            size: 5_795_643,
                            md5: '635d4505b9dfd1b49ab346c8209e09f7',
                            content_type: 'image/jpeg',
                            yandex_token: token
    end

    let!(:photo4) { create :photo, :fake, storage_filename: '000/013/zzz.jpg', yandex_token: token }

    it do
      is_expected.to be_a_success

      expect(subject.errors.keys).to eq([photo4.id])
      expect(subject.errors[photo4.id]).to eq(['not found on remote storage'])
    end
  end

  context 'when wrong photo info' do
    let!(:photo3) do
      create :photo, :fake, storage_filename: '000/013/6516fdedf98ba516916be55f04faeec88d14718325dc.jpg',
                            size: 5_795_644,
                            md5: '635d4505b9dfd1b49ab346c8209e09f8',
                            content_type: 'image/png',
                            yandex_token: token
    end

    it do
      is_expected.to be_a_success

      expect(subject.errors.keys).to eq([photo3.id])
      expect(subject.errors[photo3.id]).to match_array([
        'size mismatch',
        'content type mismatch',
        'etag mismatch'
      ])
    end
  end
end
