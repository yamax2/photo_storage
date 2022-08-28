# frozen_string_literal: true

RSpec.describe Yandex::BackupInfoService do
  let(:backup_secret) { 'very_secret' }
  let(:token) do
    create :'yandex/token', dir: '/test',
                            other_dir: '/other',
                            access_token: API_ACCESS_TOKEN,
                            login: 'test@ya.ru'
  end

  let(:decoded_string) do
    src = Base64.decode64(encoded_string)

    decryptor = OpenSSL::Cipher.new('aes-256-cbc').decrypt.tap do |cipher|
      cipher.key = Digest::SHA256.digest(backup_secret)
      cipher.iv = Digest::MD5.digest(token.login)
    end

    decryptor.update(src) + decryptor.final
  end

  context 'when without backup secret' do
    let(:backup_secret) { nil }

    it do
      expect { described_class.call!(token:, resource: :photo, backup_secret:) }.
        to raise_error(/backup secret/)
    end
  end

  context 'when wrong resource' do
    it do
      expect { described_class.call!(token:, resource: :wrong, backup_secret:) }.
        to raise_error(described_class::WrongResourceError, 'wrong resource passed: "wrong"')
    end
  end

  context 'when photos' do
    subject(:encoded_string) do
      VCR.use_cassette('yandex_download_url_photos') do
        described_class.call!(token:, resource: :photo, backup_secret:).info
      end
    end

    it do
      expect(encoded_string).not_to be_empty
      expect(decoded_string).to include('https://downloader.disk.yandex.ru/zip/', 'test.zip', token.access_token)

      expect(WebMock).to have_requested(:get, 'https://cloud-api.yandex.net/v1/disk/resources/download?path=/test')
    end
  end

  context 'when photos and folder_index is greater than zero' do
    subject(:encoded_string) do
      VCR.use_cassette('yandex_download_url_photos2') do
        client = ::YandexClient::Dav[token.access_token]
        begin
          client.propfind('/test11')
        rescue ::YandexClient::NotFoundError
          client.mkcol('/test11')
        end

        result = described_class.call!(token:, resource: :photo, backup_secret:, folder_index: 11).info
        client.delete('/test11')

        result
      end
    end

    it do
      expect(encoded_string).not_to be_empty
      expect(decoded_string).to include('https://downloader.disk.yandex.ru/zip/', 'test11.zip', token.access_token)

      expect(WebMock).to have_requested(:get, 'https://cloud-api.yandex.net/v1/disk/resources/download?path=/test11')
    end
  end

  context 'when other' do
    subject(:encoded_string) do
      VCR.use_cassette('yandex_download_url_other') do
        described_class.call!(token:, resource: 'other', backup_secret:).info
      end
    end

    it do
      expect(encoded_string).not_to be_empty

      expect(decoded_string).to include('https://downloader.disk.yandex.ru/zip/', 'other.zip', token.access_token)
    end
  end

  context 'when other and folder_index is greater than zero' do
    subject(:encoded_string) do
      VCR.use_cassette('yandex_download_url_other2') do
        client = ::YandexClient::Dav[token.access_token]
        begin
          client.propfind('/other12')
        rescue ::YandexClient::NotFoundError
          client.mkcol('/other12')
        end

        result = described_class.call!(token:, resource: :other, backup_secret:, folder_index: 12).info
        client.delete('/other12')

        result
      end
    end

    it do
      expect(encoded_string).not_to be_empty

      expect(decoded_string).to include('https://downloader.disk.yandex.ru/zip/', 'other12.zip', token.access_token)

      expect(WebMock).to have_requested(:get, 'https://cloud-api.yandex.net/v1/disk/resources/download?path=/other12')
    end
  end

  context 'when path is blank' do
    let(:token) { create :'yandex/token', dir: nil }

    it do
      expect { described_class.call!(token:, resource: :photo, backup_secret:) }.
        to raise_error("no dir for photo for token #{token.id}")
    end
  end
end
