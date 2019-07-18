require 'rails_helper'

RSpec.describe Yandex::ReviseJob do
  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  let(:run_job) do
    described_class.perform_async
    described_class.drain
  end

  context 'when photos exist' do
    let(:token1) { create :'yandex/token', dir: '/test1' }
    let(:token2) { create :'yandex/token', dir: '/test2' }

    let!(:photo1) { create :photo, :fake, yandex_token: token1, storage_filename: '000/013/test1.jog' }
    let!(:photo2) { create :photo, :fake, yandex_token: token1, storage_filename: '000/014/test2.jog' }
    let!(:photo3) { create :photo, :fake, yandex_token: token2, storage_filename: '000/013/test3.jog' }

    let!(:unpublished_photo) { create :photo, :fake, yandex_token: token1, local_filename: 'test.jpg' }

    it do
      expect { run_job }.to change { Yandex::ReviseDirJob.jobs.size }.by(3)
    end
  end

  context 'when without photos' do
    it do
      expect { run_job }.not_to(change { Yandex::ReviseDirJob.jobs.size })
    end
  end

  after { Sidekiq::Worker.clear_all }
end
