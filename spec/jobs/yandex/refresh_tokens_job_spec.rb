require 'rails_helper'

RSpec.describe Yandex::RefreshTokensJob do
  before do
    allow(Yandex::RefreshTokenJob).to receive(:perform_async)
  end

  context 'when some tokens' do
    let!(:token1) { create :'yandex/token' }
    let!(:token2) { create :'yandex/token' }

    before { described_class.perform_async }

    it do
      expect(Yandex::RefreshTokenJob).to have_received(:perform_async).with(token1.id)
      expect(Yandex::RefreshTokenJob).to have_received(:perform_async).with(token2.id)
    end
  end

  context 'when without tokens' do
    before { described_class.perform_async }

    it do
      expect(Yandex::RefreshTokenJob).not_to have_received(:perform_async)
    end
  end
end
