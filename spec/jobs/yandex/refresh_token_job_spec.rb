# frozen_string_literal: true

RSpec.describe Yandex::RefreshTokenJob do
  before do
    allow(Yandex::RefreshTokenService).to receive(:call!)
    allow(Yandex::RefreshQuotaService).to receive(:call!)

    token
  end

  context 'when token exists' do
    let(:token) { create :'yandex/token' }

    before { described_class.new.perform(token.id) }

    it do
      expect(Yandex::RefreshTokenService).to have_received(:call!)
      expect(Yandex::RefreshQuotaService).to have_received(:call!)
    end
  end

  context 'when token does not exist' do
    let(:token) { Struct.new(:id).new(id: 1) }

    it do
      expect { described_class.new.perform(token.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
