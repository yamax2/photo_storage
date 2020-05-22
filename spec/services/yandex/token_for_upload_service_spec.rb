# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Yandex::TokenForUploadService do
  let(:redis) { RedisClassy.redis }

  let(:service_context) { described_class.call!(resource_size: 100.megabytes) }
  let(:token_id) { service_context.token_id }

  context 'when without tokens' do
    it { expect(token_id).to be_nil }
  end

  context 'when without active tokens' do
    before { create :'yandex/token', total_space: 150.megabytes, used_space: 10.megabytes, active: false }

    it { expect(token_id).to be_nil }
  end

  context 'when without actual tokens' do
    before { create :'yandex/token', total_space: 150.megabytes, used_space: 130.megabytes, active: true }

    it { expect(token_id).to be_nil }
  end

  context 'when some tokens exist' do
    before { create :'yandex/token', total_space: 150.megabytes, used_space: 0, active: false }

    let!(:token2) { create :'yandex/token', total_space: 150.megabytes, used_space: 30.megabytes, active: true }
    let!(:token3) { create :'yandex/token', total_space: 150.megabytes, used_space: 30.megabytes, active: true }

    context 'and first call' do
      it { expect(token_id).to eq(token2.id) }
    end

    context 'and second call' do
      before { described_class.call!(resource_size: 100.megabytes) }

      it { expect(token_id).to eq(token3.id) }
    end
  end

  context 'when no free space on first token' do
    before { create :'yandex/token', total_space: 150.megabytes, used_space: 130.megabytes, active: true }

    let!(:token2) { create :'yandex/token', total_space: 150.megabytes, used_space: 30.megabytes, active: true }

    it { expect(token_id).to eq(token2.id) }
  end

  context 'when no free space' do
    before do
      create :'yandex/token', total_space: 150.megabytes, used_space: 130.megabytes, active: true
      create :'yandex/token', total_space: 150.megabytes, used_space: 140.megabytes, active: true
    end

    it { expect(token_id).to be_nil }
  end

  context 'when no free space (redis counter)' do
    let(:token2) { create :'yandex/token', total_space: 150.megabytes, used_space: 40.megabytes, active: true }

    before do
      create :'yandex/token', total_space: 150.megabytes, used_space: 130.megabytes, active: true

      redis.hset('yandex_tokens_usage', token2.id, 100.megabytes)
    end

    it { expect(token_id).to be_nil }
  end

  context 'when wrong token_id in redis' do
    let!(:token2) { create :'yandex/token', total_space: 150.megabytes, used_space: 40.megabytes, active: true }

    before do
      create :'yandex/token', total_space: 150.megabytes, used_space: 130.megabytes, active: true

      redis.hset('yandex_tokens_usage', 0, 100.megabytes)
    end

    it { expect(token_id).to eq(token2.id) }
  end
end
