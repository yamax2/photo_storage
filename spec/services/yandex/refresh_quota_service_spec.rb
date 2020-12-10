# frozen_string_literal: true

RSpec.describe Yandex::RefreshQuotaService do
  let(:redis) { RedisClassy.redis }
  let(:token) { create :'yandex/token', access_token: API_ACCESS_TOKEN }
  let(:service_context) { described_class.call!(token: token) }

  before do
    redis.hset('yandex_tokens_usage', token.id, 100.megabytes)
  end

  context 'regular call' do
    subject(:refresh!) do
      VCR.use_cassette('refresh_quota') { service_context }
    end

    it do
      expect { refresh! }.to(
        change { token.reload.used_space }.
        and(change(token, :total_space)).
        and(change { redis.hgetall('yandex_tokens_usage') }.from(token.id.to_s => 100.megabytes.to_s).to({}))
      )
    end
  end

  context 'when api is unreachable' do
    before { stub_request(:any, /cloud-api.yandex.net/).to_timeout }

    it do
      expect { service_context }.
        to raise_error(Net::OpenTimeout).
        and change { redis.hgetall('yandex_tokens_usage').size }.by(0)
    end
  end

  context 'when db transaction fails' do
    subject(:refresh!) do
      VCR.use_cassette('refresh_quota') { service_context }
    end

    before do
      allow(token).to receive(:update!).and_raise('boom!')
    end

    it do
      expect { refresh! }.
        to raise_error('boom!').
        and change { redis.hgetall('yandex_tokens_usage').size }.by(0)
    end
  end
end
