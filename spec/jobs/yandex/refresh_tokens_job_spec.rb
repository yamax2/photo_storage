# frozen_string_literal: true

RSpec.describe Yandex::RefreshTokensJob do
  context 'when some tokens' do
    let!(:token1) { create :'yandex/token' }
    let!(:token2) { create :'yandex/token' }

    before { described_class.new.perform }

    it do
      expect(enqueued_jobs('tokens', klass: Yandex::RefreshTokenJob).map { |j| j['args'] }.flatten).
        to match_array([token1.id, token2.id])
    end
  end

  context 'when without tokens' do
    it do
      expect { described_class.new.perform }.not_to(change { enqueued_jobs('tokens').size })
    end
  end
end
