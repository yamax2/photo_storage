# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Yandex::ReviseDirJob do
  let!(:token) { create :'yandex/token', dir: '/test' }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  let(:run_job) do
    described_class.perform_async('000/013/', token.id)
    described_class.drain
  end

  context 'when errors' do
    subject do
      VCR.use_cassette('yandex_revise_dir') { run_job }
    end

    it do
      expect { subject }.
        to change { Sidekiq::Extensions::DelayedMailer.jobs.size }.by(1)
    end
  end

  context 'when without errors' do
    before do
      expect(Yandex::ReviseDirService).to receive(:call!).and_return(Struct.new(:errors).new({}))
    end

    it do
      expect { run_job }.not_to(change { Sidekiq::Extensions::DelayedMailer.jobs.size })
    end
  end

  after { Sidekiq::Worker.clear_all }
end
