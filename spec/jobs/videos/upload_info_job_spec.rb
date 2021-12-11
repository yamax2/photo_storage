# frozen_string_literal: true

RSpec.describe Videos::UploadInfoJob do
  subject(:run!) { described_class.new.perform(model.id, key) }

  let(:node) { create :'yandex/token' }
  let(:key) { 'test_key' }

  context 'when video exists' do
    let(:service) { double }
    let(:model) { create :photo, :video, yandex_token: node, storage_filename: 'test.mp4' }

    before do
      allow(Videos::UploadInfoService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return('info')
    end

    it do
      expect { run! }.to change { RedisClassy.get(key) }.from(nil).to('info')

      expect(RedisClassy.ttl(key)).to be_positive
    end
  end

  context 'when wrong video' do
    subject(:run!) { described_class.new.perform(1, key) }

    it do
      expect { run! }.not_to raise_error

      expect(RedisClassy.exists?(key)).to eq(false)
    end
  end

  context 'when wrong content_type' do
    let(:model) { create :photo, content_type: 'image/jpeg', yandex_token: node, storage_filename: '1.jpg' }

    it do
      expect { run! }.not_to raise_error

      expect(RedisClassy.exists?(key)).to eq(false)
    end
  end
end
