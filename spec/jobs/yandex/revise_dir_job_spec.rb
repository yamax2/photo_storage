require 'rails_helper'

RSpec.describe Yandex::ReviseDirJob do
  let(:token) { create :'yandex/token' }

  context 'when errors' do

  end

  context 'when without errors' do
    before do
      expect(Yandex::ReviseDirService).to receive(:call!).and_return(Struct.new(:errors).new({}))
    end

    it do
      expect { described_class.perform_async('000/013', token.id) }.
        to change { Sidekiq::Extensions::DelayedMailer.jobs.size }.by(1)
    end
  end
end
