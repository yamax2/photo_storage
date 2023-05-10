# frozen_string_literal: true

RSpec.describe RedisScript do
  let(:script) { 'return redis.call("GETSET", KEYS[1], ARGV[1])' }
  let(:redis) { Rails.application.redis }
  let(:service) { described_class.new(script) }

  context 'when first time exec' do
    before do
      allow(redis).to receive(:call).and_call_original
    end

    it do
      expect { service.exec(keys: 'test', argv: 5) }.
        to change { redis.call('GET', 'test') }.from(nil).to('5')

      expect(redis).to have_received(:call).with('EVAL', any_args)
    end
  end

  context 'when second time exec' do
    before do
      service.exec(keys: :test, argv: 10)

      allow(redis).to receive(:call).and_call_original
    end

    it do
      expect { service.exec(keys: 'test', argv: 5) }.
        to change { redis.call('GET', 'test') }.from('10').to('5')

      expect(redis).not_to have_received(:call).with('EVAL', any_args)
    end
  end

  context 'when error' do
    it do
      expect { service.exec(keys: 'test') }.
        to raise_error(RedisClient::CommandError)
    end
  end
end
