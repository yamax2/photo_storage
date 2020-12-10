# frozen_string_literal: true

RSpec.describe Yandex::ReviseDirJob do
  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  let!(:token) { create :'yandex/token', dir: '/test' }

  let(:run_job) do
    described_class.perform_async('000/013/', token.id)
    described_class.drain
  end

  after { Sidekiq::Worker.clear_all }

  context 'when errors' do
    subject(:request) do
      VCR.use_cassette('yandex_revise_dir') { run_job }
    end

    it do
      expect { request }.
        to change { Sidekiq::Extensions::DelayedMailer.jobs.size }.by(1)
    end
  end

  context 'when without errors' do
    before do
      allow(Yandex::ReviseDirService).to receive(:call!).and_return(Struct.new(:errors).new({}))
    end

    it do
      expect { run_job }.not_to(change { Sidekiq::Extensions::DelayedMailer.jobs.size })
    end
  end
end
