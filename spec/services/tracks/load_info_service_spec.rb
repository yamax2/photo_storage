# frozen_string_literal: true

RSpec.describe Tracks::LoadInfoService do
  let(:service_context) { described_class.call(track: track) }
  let(:tmp_dir) { Rails.root.join('tmp/files') }

  before { FileUtils.rm_f(tmp_dir.join('test.gpx')) }

  context 'when correct file' do
    before do
      FileUtils.mkdir_p(tmp_dir)
      FileUtils.cp('spec/fixtures/test1.gpx', tmp_dir.join('test.gpx'))
    end

    after { FileUtils.rm_f(tmp_dir.join('test.gpx')) }

    let(:track) { create :track, local_filename: 'test.gpx' }
    let(:correct_attrs) do
      {
        duration: 6152,
        started_at: Time.zone.local(2019, 3, 10, 11, 30, 5),
        finished_at: Time.zone.local(2019, 3, 10, 13, 12, 37),
        bounds: [
          ActiveRecord::Point.new(58.8514683, 56.8266267),
          ActiveRecord::Point.new(59.4318817, 57.670655)
        ]
      }
    end

    it do
      expect(service_context).to be_a_success

      expect(track.avg_speed.round(2)).to eq(60.58)
      expect(track.distance.round(2)).to eq(103.53)

      expect(track).to have_attributes(correct_attrs)
    end
  end

  context 'when file with gaps' do
    before do
      FileUtils.mkdir_p(tmp_dir)
      FileUtils.cp('spec/fixtures/test3.gpx', tmp_dir.join('test.gpx'))
    end

    after { FileUtils.rm_f(tmp_dir.join('test.gpx')) }

    let(:track) { create :track, local_filename: 'test.gpx' }

    it do
      expect(service_context).to be_a_success

      expect(track.distance.round(2)).to eq(137.45)
      expect(track.avg_speed.round(2)).to eq(55.34)

      expect(track).to have_attributes(
        duration: 8942,
        started_at: Time.zone.local(2021, 2, 21, 17, 10, 59),
        finished_at: Time.zone.local(2021, 2, 21, 20, 51, 47)
      )
    end
  end

  context 'when tmp file does not exist' do
    let(:track) { create :track, local_filename: 'test.gpx' }

    it do
      expect { service_context }.not_to change(track, :bounds)

      expect(service_context).to be_a_success
      expect(track).to have_attributes(avg_speed: 0, distance: 0, duration: 0)
    end
  end

  context 'when file already uploaded' do
    let(:token) { create :'yandex/token' }
    let(:track) { create :track, storage_filename: 'test.gpx', yandex_token: token }

    it do
      expect { service_context }.not_to change(track, :bounds)

      expect(service_context).to be_a_success
      expect(track).to have_attributes(avg_speed: 0, distance: 0, duration: 0)
    end
  end

  context 'when track with values' do
    before do
      FileUtils.mkdir_p(tmp_dir)
      FileUtils.cp('spec/fixtures/test1.gpx', tmp_dir.join('test.gpx'))
    end

    after { FileUtils.rm_f(tmp_dir.join('test.gpx')) }

    let(:track) { create :track, local_filename: 'test.gpx', distance: 20 }
    let(:correct_bounds) do
      [
        ActiveRecord::Point.new(58.8514683, 56.8266267),
        ActiveRecord::Point.new(59.4318817, 57.670655)
      ]
    end

    it do
      expect(service_context).to be_a_success

      expect(track.avg_speed.round(2)).to eq(60.58)
      expect(track.distance.round(2)).to eq(103.53)
      expect(track.duration).to eq(6152)
      expect(track.bounds).to eq(correct_bounds)
    end
  end
end
