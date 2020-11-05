# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Yandex::EnqueueBackupInfoService do
  let(:redis) { RedisClassy.redis }
  let(:token) { create :'yandex/token', dir: '/test', other_dir: '/other', access_token: API_ACCESS_TOKEN }

  let(:resource) { :photo }
  let(:service_context) { described_class.call!(token: token, resource: resource) }
  let(:redis_key) { "backup_info:#{token.id}:photo" }

  context 'when info presents' do
    before { redis.set(redis_key, 'test') }

    it do
      expect(Yandex::BackupInfoJob).not_to receive(:perform_async)

      expect { service_context }.to change { redis.type(redis_key) }.from('string').to('none')

      expect(service_context.info).to eq('test')
    end
  end

  context 'when job enqueued' do
    before { redis.set(redis_key, nil) }

    it do
      expect(Yandex::BackupInfoJob).not_to receive(:perform_async)

      expect { service_context }.not_to(change { redis.get(redis_key) })
      expect(service_context.info).to be_nil
    end
  end

  context 'when a new job is required' do
    it do
      expect(Yandex::BackupInfoJob).to receive(:perform_async).with(token.id, :photo, redis_key)

      expect { service_context }.to change { redis.type(redis_key) }.from('none').to('string')

      expect(redis.get(redis_key)).to be_empty
      expect(service_context.info).to be_nil
    end
  end

  context 'when wrong resource' do
    let(:resource) { 'wrong' }

    it do
      expect(Yandex::BackupInfoJob).not_to receive(:perform_async)

      expect { service_context }.
        to raise_error(Yandex::BackupInfoService::WrongResourceError, 'wrong resource passed: "wrong"')

      expect(redis.get(redis_key)).to be_nil
    end
  end
end
