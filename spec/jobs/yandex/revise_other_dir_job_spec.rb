# frozen_string_literal: true

RSpec.describe Yandex::ReviseOtherDirJob do
  subject(:run_job!) { described_class.new.perform(token.id, 0) }

  let!(:token) { create :'yandex/token', other_dir: '/other_dev' }

  context 'when errors' do
    let(:request) { VCR.use_cassette('yandex_revise_other_dir') { run_job! } }

    it do
      expect { request }.
        to change { enqueued_jobs(klass: Sidekiq::Extensions::DelayedMailer).size }.by(1)
    end
  end

  context 'when without errors' do
    before do
      allow(Yandex::ReviseOtherDirService).to receive(:call!).and_return(Struct.new(:errors).new({}))
    end

    it do
      expect { run_job! }.not_to change(enqueued_jobs, :size)
    end
  end
end
