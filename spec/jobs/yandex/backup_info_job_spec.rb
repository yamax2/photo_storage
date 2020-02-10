# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Yandex::BackupInfoJob do
  let(:redis) { RedisClassy.redis }
  let(:token) { create :'yandex/token', dir: '/test', other_dir: '/other', access_token: API_ACCESS_TOKEN }

  context 'when correct resource' do
    subject do
      VCR.use_cassette('yandex_download_url_photos') do
        described_class.perform_async(token.id, :photos, 'test')
      end
    end

    it do
      expect { subject }.
        to change { redis.get('test') }.from(nil).to(String)

      expect(redis.ttl('test')).to eq(described_class::INFO_KEY_TTL)
    end
  end

  context 'when wrong resource' do
    subject { described_class.perform_async(token.id, :wrong, 'test') }

    it do
      expect { subject }.to raise_error(Yandex::BackupInfoService::WrongResourceError)
    end
  end
end