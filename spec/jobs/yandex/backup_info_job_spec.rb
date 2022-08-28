# frozen_string_literal: true

RSpec.describe Yandex::BackupInfoJob do
  let(:redis) { RedisClassy.redis }
  let(:token) { create :'yandex/token', dir: '/test', other_dir: '/other', access_token: API_ACCESS_TOKEN }

  before do
    allow(Rails.application.credentials).to receive(:backup_secret).and_return('very_secret')
  end

  context 'when correct resource' do
    subject(:request) do
      VCR.use_cassette('yandex_download_url_photos') do
        described_class.new.perform(token.id, :photo, 0, 'test')
      end
    end

    it do
      expect { request }.
        to change { redis.get('test') }.from(nil).to(String)

      expect(redis.ttl('test')).to eq(described_class::INFO_KEY_TTL)
    end
  end

  context 'when correct resource and folder_index is greater than zero' do
    subject(:request) do
      VCR.use_cassette('yandex_download_url_photos2') do
        described_class.new.perform(token.id, :photo, 11, 'test')
      end
    end

    it do
      expect { request }.
        to change { redis.get('test') }.from(nil).to(String)

      expect(redis.ttl('test')).to eq(described_class::INFO_KEY_TTL)
    end
  end

  context 'when wrong resource' do
    subject(:request) { described_class.new.perform(token.id, :wrong, 100, 'test') }

    it do
      expect { request }.to raise_error(Yandex::BackupInfoService::WrongResourceError)
    end
  end
end
