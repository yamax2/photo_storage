# frozen_string_literal: true

RSpec.describe RedisScriptService do
  let(:script) { 'return redis.call("GETSET", KEYS[1], ARGV[1])' }
  let(:redis) { RedisClassy.redis }
  let(:service) { described_class.new(script) }

  context 'when first time exec' do
    it do
      expect(redis).to receive(:eval).and_call_original

      expect { service.call(keys: :test, argv: 5) }.
        to change { redis.get('test') }.from(nil).to('5')
    end
  end

  context 'when second time exec' do
    before { service.call(keys: :test, argv: 10) }

    it do
      expect(redis).not_to receive(:eval)

      expect { service.call(keys: :test, argv: 5) }.
        to change { redis.get('test') }.from('10').to('5')
    end
  end

  context 'when error' do
    it do
      expect { service.call(keys: :test) }.to raise_error(Redis::CommandError)
    end
  end
end
