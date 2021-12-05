# frozen_string_literal: true

RSpec.describe Video::UploadInfoService do
  subject(:info) { described_class.new(video, secret: secret).call }

  let(:secret) { 'very_secret' }
  let(:node) { create :'yandex/token', other_dir: '/other' }
  let(:video) { create :photo, :video, storage_filename: 'test.mp4', yandex_token: node, size: 2_000 }

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

  it do
    expect(info).to be_a(String)

    expect(decoded_info).to include(
      'video' => {
        'url' => 'https://webdav.yandex.ru/other/test.mp4',
        'headers' => {
          'Authorization' => "OAuth #{node.access_token}",
          'Content-Length' => video.size,
          'Etag' => video.md5,
          'Sha256' => video.sha256,
          'Expect' => '100-continue'
        }
      },
      'preview' => {
        'url' => 'https://webdav.yandex.ru/other/test.mp4.jpg',
        'headers' => {
          'Authorization' => "OAuth #{node.access_token}",
          'Content-Length' => video.preview_size,
          'Etag' => video.preview_md5,
          'Sha256' => video.preview_sha256,
          'Expect' => '100-continue'
        }
      }
    )
  end
end
