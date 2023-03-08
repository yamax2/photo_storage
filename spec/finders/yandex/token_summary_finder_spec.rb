# frozen_string_literal: true

RSpec.describe Yandex::TokenSummaryFinder do
  subject(:scope) { described_class.call }

  let!(:token1) { create :'yandex/token' }
  let!(:token2) { create :'yandex/token' }
  let(:last_upload_at) do
    scope.to_h { |x| x.slice(:id, :last_upload_at).values }
  end

  let(:current_time) { Time.zone.local(2017, 1, 1, 15, 45, 55) }
  let(:default_tz) { Rails.application.config.time_zone }

  before do
    Timecop.freeze(current_time)

    create :photo, local_filename: '1.jpg', created_at: 1.day.from_now, yandex_token: token1
    create :track, local_filename: '2.gpx', created_at: 1.day.from_now, yandex_token: token2
  end

  after { Timecop.return }

  context 'when without uploaded models' do
    it do
      expect(scope.to_a).to contain_exactly(token1, token2)

      expect(last_upload_at.values.compact).to be_empty
    end
  end

  context 'when only photos uploaded for token' do
    before do
      create :photo, storage_filename: '1.jpg', created_at: current_time, yandex_token: token1
      create :photo, storage_filename: '2.jpg', created_at: current_time - 1.day, yandex_token: token1
    end

    it do
      expect(scope.to_a).to contain_exactly(token1, token2)

      expect(last_upload_at[token1.id]).to eq(current_time)
      expect(last_upload_at[token1.id].time_zone.name).to eq(default_tz)
      expect(last_upload_at[token2.id]).to be_nil
    end
  end

  context 'when only tracks uploaded' do
    before do
      create :track, storage_filename: '1.gpx', created_at: 1.day.from_now, yandex_token: token1
      create :track, storage_filename: '1.gpx', created_at: current_time, yandex_token: token1
    end

    it do
      expect(scope.to_a).to contain_exactly(token1, token2)

      expect(last_upload_at[token1.id]).to eq(1.day.from_now)
      expect(last_upload_at[token1.id].time_zone.name).to eq(default_tz)
      expect(last_upload_at[token2.id]).to be_nil
    end
  end

  context 'when photos and tracks uploaded for token' do
    before do
      create :photo, storage_filename: '1.jpg', created_at: current_time, yandex_token: token1
      create :photo, storage_filename: '2.jpg', created_at: 1.day.ago, yandex_token: token1

      create :track, storage_filename: '1.gpx', created_at: 1.day.from_now, yandex_token: token1
      create :track, storage_filename: '1.gpx', created_at: current_time, yandex_token: token1
    end

    it do
      expect(scope.to_a).to contain_exactly(token1, token2)

      expect(last_upload_at[token1.id]).to eq(1.day.from_now)
      expect(last_upload_at[token1.id].time_zone.name).to eq(default_tz)
      expect(last_upload_at[token2.id]).to be_nil
    end
  end

  describe 'ransack and pagination' do
    subject(:scope) { described_class.call.page(1).ransack(s: 'last_upload_at desc').result }

    before do
      create :photo, storage_filename: '1.jpg', created_at: current_time, yandex_token: token1
      create :photo, storage_filename: '2.jpg', created_at: 1.day.from_now, yandex_token: token2

      create :track, storage_filename: '1.gpx', created_at: 1.day.ago, yandex_token: token1
      create :track, storage_filename: '1.gpx', created_at: current_time, yandex_token: token2
    end

    it do
      expect(scope.to_a).to eq([token2, token1])
      expect(scope.total_pages).to eq(1)

      expect(last_upload_at[token1.id]).to eq(current_time)
      expect(last_upload_at[token1.id].time_zone.name).to eq(default_tz)

      expect(last_upload_at[token2.id]).to eq(1.day.from_now)
      expect(last_upload_at[token2.id].time_zone.name).to eq(default_tz)
    end
  end
end
