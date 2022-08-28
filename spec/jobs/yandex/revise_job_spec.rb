# frozen_string_literal: true

RSpec.describe Yandex::ReviseJob do
  subject(:run_job!) { described_class.new.perform }

  context 'when photos, tracks and videos exist' do
    let(:token1) { create :'yandex/token', dir: '/test1' }
    let(:token2) { create :'yandex/token', dir: '/test2' }
    let(:token3) { create :'yandex/token', dir: '/test3' }

    before do
      create :photo, yandex_token: token1, storage_filename: '000/013/test1.jpg'
      create :photo, yandex_token: token1, storage_filename: '000/014/test2.jpg'
      create :photo, yandex_token: token2, storage_filename: '000/013/test3.jpg', folder_index: 1
      create :photo, yandex_token: token2, storage_filename: '000/013/test4.jpg'

      create :photo, yandex_token: token1, local_filename: 'test.jpg'

      create :track, yandex_token: token2, storage_filename: '111.gpx'
      create :track, yandex_token: token2, storage_filename: '112.gpx'

      create :photo, :video, yandex_token: token1, storage_filename: '113.mp4'
      create :photo, :video, yandex_token: token3, storage_filename: '114.mp4'
      create :photo, :video, yandex_token: token3, storage_filename: '115.mp4', folder_index: 1
    end

    it do
      expect { run_job! }.
        to change { enqueued_jobs(klass: Yandex::ReviseDirJob).size }.by(4).
        and change { enqueued_jobs(klass: Yandex::ReviseOtherDirJob).size }.by(4)

      expect(enqueued_jobs(klass: Yandex::ReviseDirJob).map { |x| x['args'] }).to match_array(
        [
          ['000/013/', token1.id, 0],
          ['000/014/', token1.id, 0],
          ['000/013/', token2.id, 0],
          ['000/013/', token2.id, 1]
        ]
      )

      expect(enqueued_jobs(klass: Yandex::ReviseOtherDirJob).map { |x| x['args'] }).to match_array(
        [
          [token1.id, 0],
          [token2.id, 0],
          [token3.id, 0],
          [token3.id, 1]
        ]
      )
    end
  end

  context 'when only videos exist' do
    let(:token) { create :'yandex/token', dir: '/test1' }

    before do
      create :photo, :video, yandex_token: token, storage_filename: '112.mp4'
      create :photo, :video, yandex_token: token, storage_filename: '113.mp4', folder_index: 2
    end

    it do
      expect { run_job! }.
        to change { enqueued_jobs(klass: Yandex::ReviseDirJob).size }.by(0).
        and change { enqueued_jobs(klass: Yandex::ReviseOtherDirJob).size }.by(2)

      expect(enqueued_jobs(klass: Yandex::ReviseOtherDirJob).map { |x| x['args'] }).to match_array(
        [
          [token.id, 0],
          [token.id, 2]
        ]
      )
    end
  end

  context 'when without any resources' do
    it do
      expect { run_job! }.not_to change(enqueued_jobs, :size)
    end
  end

  context 'when only tracks exist' do
    let(:token1) { create :'yandex/token' }

    before do
      create :track, yandex_token: token1, storage_filename: '112.gpx'
      create :track, yandex_token: token1, storage_filename: '113.gpx', folder_index: 2
    end

    it do
      expect { run_job! }.
        to change { enqueued_jobs(klass: Yandex::ReviseDirJob).size }.by(0).
        and change { enqueued_jobs(klass: Yandex::ReviseOtherDirJob).size }.by(2)

      expect(enqueued_jobs(klass: Yandex::ReviseOtherDirJob).map { |x| x['args'] }).to match_array(
        [
          [token1.id, 0],
          [token1.id, 2]
        ]
      )
    end
  end
end
