# frozen_string_literal: true

RSpec.describe Yandex::ReviseDirJob do
  subject(:run_job!) { described_class.new.perform('000/013/', token.id) }

  let!(:token) { create :'yandex/token', dir: '/test' }

  context 'when errors' do
    subject(:request) { VCR.use_cassette('yandex_revise_dir') { run_job! } }

    it do
      expect { request }.
        to change { enqueued_jobs(klass: Sidekiq::Extensions::DelayedMailer).size }.by(1)
    end
  end

  context 'when without errors' do
    before do
      allow(Yandex::ReviseDirService).to receive(:call!).and_return(Struct.new(:errors).new({}))
    end

    it do
      expect { run_job! }.
        not_to(change { enqueued_jobs(klass: Sidekiq::Extensions::DelayedMailer).size })
    end
  end
end
