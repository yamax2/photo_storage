# frozen_string_literal: true

RSpec.describe Yandex::EnqueueBackupInfoService do
  let(:redis) { Rails.application.redis }
  let(:token) { create :'yandex/token', dir: '/test', other_dir: '/other', access_token: API_ACCESS_TOKEN }

  let(:resource) { :photo }
  let(:folder_index) { 9 }
  let(:service_context) { described_class.call!(token:, resource:, folder_index:) }
  let(:redis_key) { "backup_info:#{token.id}:photo:#{folder_index}" }

  context 'when info presents' do
    before { redis.call('SET', redis_key, 'test') }

    it do
      expect(Yandex::BackupInfoJob).not_to receive(:perform_async)

      expect { service_context }.to change { redis.call('TYPE', redis_key) }.from('string').to('none')

      expect(service_context.info).to eq('test')
    end
  end

  context 'when job enqueued' do
    before { redis.call('SET', redis_key, '') }

    it do
      expect(Yandex::BackupInfoJob).not_to receive(:perform_async)

      expect { service_context }.not_to(change { redis.call('GET', redis_key) })
      expect(service_context.info).to be_nil
    end
  end

  context 'when a new job is required' do
    it do
      expect(Yandex::BackupInfoJob).to receive(:perform_async).with(token.id, :photo, folder_index, redis_key)

      expect { service_context }.to change { redis.call('TYPE', redis_key) }.from('none').to('string')

      expect(redis.call('GET', redis_key)).to eq('')
      expect(service_context.info).to be_nil
    end
  end

  context 'when wrong resource' do
    let(:resource) { 'wrong' }

    it do
      expect(Yandex::BackupInfoJob).not_to receive(:perform_async)

      expect { service_context }.
        to raise_error(Yandex::BackupInfoService::WrongResourceError, 'wrong resource passed: "wrong"')

      expect(redis.call('GET', redis_key)).to be_nil
    end
  end
end
