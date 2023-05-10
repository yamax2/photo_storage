# frozen_string_literal: true

RSpec.describe Videos::UploadInfoJob do
  subject(:run!) { described_class.new.perform(model.id, key, false) }

  let(:node) { create :'yandex/token' }
  let(:key) { 'test_key' }
  let(:redis) { Rails.application.redis }

  context 'when video exists' do
    let(:service) { double }
    let(:model) { create :photo, :video, yandex_token: node, storage_filename: 'test.mp4' }

    before do
      allow(Videos::UploadInfoService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return('info')
    end

    it do
      expect { run! }.to change { redis.call('GET', key) }.from(nil).to('info')

      expect(redis.call('TTL', key)).to be_positive
    end
  end

  context 'when wrong video' do
    subject(:run!) { described_class.new.perform(1, key, false) }

    it do
      expect { run! }.not_to raise_error

      expect(redis.call('KEYS', key)).to be_empty
    end
  end

  context 'when wrong content_type' do
    let(:model) { create :photo, content_type: 'image/jpeg', yandex_token: node, storage_filename: '1.jpg' }

    it do
      expect { run! }.not_to raise_error

      expect(redis.call('KEYS', key)).to be_empty
    end
  end

  context 'when skip original' do
    subject(:run!) { described_class.new.perform(model.id, key, true) }

    let(:service) { double }
    let(:model) { create :photo, :video, yandex_token: node, storage_filename: 'test.mp4' }

    before do
      allow(Videos::UploadInfoService).to receive(:new).with(model, skip_original: true).and_return(service)
      allow(service).to receive(:call).and_return('info')
    end

    it do
      expect { run! }.not_to raise_error

      expect(redis.call('GET', key)).to eq('info')
    end
  end
end
