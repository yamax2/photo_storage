# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Yandex::ReviseOtherDirJob do
  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  let!(:token) { create :'yandex/token', other_dir: '/other' }

  let(:run_job) do
    described_class.perform_async(token.id)
    described_class.drain
  end

  after { Sidekiq::Worker.clear_all }

  context 'when errors' do
    subject(:request) { VCR.use_cassette('yandex_revise_other_dir') { run_job } }

    it do
      expect { request }.
        to change { Sidekiq::Extensions::DelayedMailer.jobs.size }.by(1)
    end
  end

  context 'when without errors' do
    before do
      allow(Yandex::ReviseOtherDirService).to receive(:call!).and_return(Struct.new(:errors).new({}))
    end

    it do
      expect { run_job }.not_to(change { Sidekiq::Extensions::DelayedMailer.jobs.size })
    end
  end
end
