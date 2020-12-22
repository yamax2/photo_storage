# frozen_string_literal: true

RSpec.describe Tracks::RemoveFileJob do
  context 'when token exists' do
    let(:token) { create :'yandex/token' }

    it do
      expect(Tracks::RemoveService).to receive(:call!).with(yandex_token: token, storage_filename: 'test')

      expect { described_class.new.perform(token.id, 'test') }.not_to raise_error
    end
  end

  context 'when token does not exist' do
    it do
      expect(Tracks::RemoveService).not_to receive(:call!)

      expect { described_class.new.perform(5, 'test') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
