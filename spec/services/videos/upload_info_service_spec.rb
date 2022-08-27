# frozen_string_literal: true

RSpec.describe Videos::UploadInfoService do
  let(:secret) { 'very_secret' }
  let(:node) { create :'yandex/token', other_dir: '/other_test', access_token: API_ACCESS_TOKEN }
  let(:folder_index) { 0 }
  let(:video) { create :photo, :video, storage_filename: 'test.mp4', yandex_token: node, size: 2_000, folder_index: }

  let(:decoded_info) do
    src = Base64.decode64(info)

    decryptor = OpenSSL::Cipher.new('aes-256-cbc').decrypt.tap do |cipher|
      cipher.key = Digest::SHA256.digest(secret)
      cipher.iv = Digest::MD5.digest(video.original_filename)
    end

    JSON.parse(
      decryptor.update(src) + decryptor.final
    )
  end

  context 'when mode with original file' do
    subject(:info) do
      VCR.use_cassette('video_upload_info') { described_class.new(video, secret:).call }
    end

    it do
      expect(info).to be_a(String)

      expect(decoded_info.fetch('video')).to include('disk.yandex.net')
      expect(decoded_info.fetch('preview')).to include('disk.yandex.net')
      expect(decoded_info.fetch('video_preview')).to include('disk.yandex.net')
    end
  end

  context 'when folder_index is greater than zero' do
    subject(:info) do
      VCR.use_cassette('video_upload_folder_index') { described_class.new(video, secret:).call }
    end

    let(:folder_index) { 3 }

    it do
      expect(info).to be_a(String)

      expect(decoded_info.fetch('video')).to include('disk.yandex.net')
      expect(decoded_info.fetch('preview')).to include('disk.yandex.net')
      expect(decoded_info.fetch('video_preview')).to include('disk.yandex.net')
    end
  end

  context 'when mode without an original file' do
    subject(:info) do
      VCR.use_cassette('video_upload_info_simple') do
        described_class.new(video, skip_original: true, secret:).call
      end
    end

    it do
      expect(info).to be_a(String)

      expect(decoded_info).not_to include('video')
      expect(decoded_info.fetch('preview')).to include('disk.yandex.net')
      expect(decoded_info.fetch('video_preview')).to include('disk.yandex.net')
    end
  end
end
