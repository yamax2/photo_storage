# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Photos::RemoveFileJob do
  before do
    allow(Photos::RemoveService).to receive(:call!)
  end

  subject { described_class.perform_async(token_id, 'test') }

  context 'when token exists' do
    let(:token) { create :'yandex/token' }
    let(:token_id) { token.id }

    before { subject }

    it do
      expect(Photos::RemoveService).to have_received(:call!).with(yandex_token: token, storage_filename: 'test')
    end
  end

  context 'when token does not exist' do
    let(:token_id) { 5 }

    it do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
