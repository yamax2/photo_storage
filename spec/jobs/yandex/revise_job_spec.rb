# frozen_string_literal: true

RSpec.describe Yandex::ReviseJob do
  subject(:run_job!) { described_class.new.perform }

  context 'when photos and tracks exist' do
    let(:token1) { create :'yandex/token', dir: '/test1' }
    let(:token2) { create :'yandex/token', dir: '/test2' }

    before do
      create :photo, yandex_token: token1, storage_filename: '000/013/test1.jog'
      create :photo, yandex_token: token1, storage_filename: '000/014/test2.jog'
      create :photo, yandex_token: token2, storage_filename: '000/013/test3.jog'

      create :photo, yandex_token: token1, local_filename: 'test.jpg'

      create :track, yandex_token: token2, storage_filename: '111.gpx'
      create :track, yandex_token: token2, storage_filename: '112.gpx'
    end

    it do
      expect { run_job! }.
        to change { enqueued_jobs(klass: Yandex::ReviseDirJob).size }.by(3).
        and change { enqueued_jobs(klass: Yandex::ReviseOtherDirJob).size }.by(1)

      expect(enqueued_jobs(klass: Yandex::ReviseDirJob).map { |x| x['args'] }).to match_array(
        [['000/013/', token1.id], ['000/014/', token1.id], ['000/013/', token2.id]]
      )

      expect(enqueued_jobs(klass: Yandex::ReviseOtherDirJob).map { |x| x['args'] }).
        to match_array([[token2.id]])
    end
  end

  context 'when without photos and tracks' do
    it do
      expect { run_job! }.not_to change(enqueued_jobs, :size)
    end
  end

  context 'when only tracks exist' do
    let(:token1) { create :'yandex/token' }

    before { create :track, yandex_token: token1, storage_filename: '112.gpx' }

    it do
      expect { run_job! }.
        to change { enqueued_jobs(klass: Yandex::ReviseDirJob).size }.by(0).
        and change { enqueued_jobs(klass: Yandex::ReviseOtherDirJob).size }.by(1)
    end
  end
end
