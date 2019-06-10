require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.inline!

RSpec.describe Yandex::RefreshTokensJob do
  before do
    allow(Yandex::RefreshTokenJob).to receive(:perform_async)
  end

  context 'when some tokens' do
    before do
      create_list(:'yandex/token', 2)

      described_class.perform_async
    end

    it do
      expect(Yandex::RefreshTokenJob).to have_received(:perform_async).twice
    end
  end

  context 'when without tokens' do
    before { described_class.perform_async }

    it do
      expect(Yandex::RefreshTokenJob).not_to have_received(:perform_async)
    end
  end
end
