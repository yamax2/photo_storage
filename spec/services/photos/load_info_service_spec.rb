require 'rails_helper'

RSpec.describe Photos::LoadInfoService do
  let(:photo) { build :photo, local_filename: filename }

  before do
    Timecop.freeze Time.new(2019, 6, 16, 13, 8, 32)

    if filename.present?
      FileUtils.mkdir_p(Rails.root.join('tmp', 'files'))
      FileUtils.cp("spec/fixtures/#{filename}", photo.tmp_local_filename)
    end

    photo.save!
    described_class.call!(photo: photo)
    photo.reload
  end

  after do
    FileUtils.rm_f(photo.tmp_local_filename) if filename.present?

    Timecop.return
  end

  context 'when correct jpg image' do
    context 'when Huawei photo' do
      let(:filename) { 'test1.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'CLT-L29', 'make' => 'HUAWEI')
        expect(photo.lat_long.to_a).to eq([56.4737777708333, 58.1308860777778])
        expect(photo).to have_attributes(
          original_timestamp: Time.new(2019, 6, 15, 21, 43, 32),
          width: 7_296,
          height: 5_472
        )
      end
    end

    context 'when HighScreen photo' do
      let(:filename) { 'test2.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'FestXL', 'make' => 'HighScreen')
        expect(photo.lat_long.to_a).to eq([56.0975074722222, 49.8604278333333])
        expect(photo).to have_attributes(
          original_timestamp: Time.new(2019, 5, 2, 18, 40, 53),
          width: 4_160,
          height: 3_120
        )
      end
    end

    context 'when asus photo' do
      let(:filename) { 'test3.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'ZB602KL', 'make' => 'asus')
        expect(photo.lat_long.to_a).to eq([59.2284763888889, 56.8072841944444])

        expect(photo).to have_attributes(
          original_timestamp: Time.new(2019, 5, 28, 18, 22, 10),
          width: 4_160,
          height: 3_120
        )
      end
    end

    context 'when jpeg without exif' do
      let(:filename) { 'cats.jpg' }

      it do
        expect(photo).to be_valid
        expect(photo).to have_attributes(
          width: 750,
          height: 750,
          original_timestamp: nil,
          lat_long: nil,
          exif: nil
        )
      end
    end

    context 'when jpeg without gps info' do
      let(:filename) { 'test4.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'FestXL', 'make' => 'HighScreen')
        expect(photo.lat_long).not_to be_present
        expect(photo).to have_attributes(width: 4_160, height: 3_120)
      end
    end

    # exif date_time is empty
    context 'when htc desire v photo' do
      let(:filename) { 'test7.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'HTC Desire V', 'make' => 'HTC')
        expect(photo.lat_long).not_to be_present
        expect(photo).to have_attributes(
          width: 2_592,
          height: 1_552,
          original_timestamp: Time.new(2013, 9, 28, 11, 37, 34)
        )
      end
    end

    context 'when asus p750 phone' do
      let(:filename) { 'test8.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'PDA/SP', 'make' => 'OEM')
        expect(photo.lat_long).not_to be_present
        expect(photo).to have_attributes(
          width: 2_048,
          height: 1_536,
          original_timestamp: Time.new(2011, 6, 12, 15, 47, 38)
        )
      end
    end

    context 'when asus p750 edited by Microsoft Windows Photo Viewer' do
      let(:filename) { 'test9.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'PDA/SP', 'make' => 'OEM')
        expect(photo.lat_long).not_to be_present
        expect(photo).to have_attributes(
          width: 1_536,
          height: 2_048,
          original_timestamp: Time.new(2011, 3, 13, 13, 34, 36)
        )
      end
    end

    context 'when exif info presents but without make and model values' do
      let(:filename) { 'test10.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).not_to be_present
        expect(photo).to have_attributes(
          width: 3_513,
          height: 1_118,
          original_timestamp: nil
        )
      end
    end
  end

  context 'when png image' do
    let(:filename) { 'cat.png' }
    let(:photo) { build :photo, local_filename: filename, content_type: 'image/png' }

    it do
      expect(photo).to be_valid
      expect(photo).to have_attributes(
        width: 400,
        height: 400,
        original_timestamp: nil,
        lat_long: nil,
        exif: nil
      )
    end
  end

  context 'when info already loaded' do
    let(:filename) { 'test2.jpg' }
    let(:photo) { build :photo, exif: {}, local_filename: filename }

    it do
      expect(photo).to be_valid
      expect(photo.exif).to be_empty
      expect(photo.lat_long).to be_nil
      expect(photo.original_timestamp).to be_nil
    end
  end

  context 'when local file does not exist' do
    let(:filename) { nil }
    let(:token) { create :'yandex/token' }
    let(:photo) do
      build :photo, :fake, local_filename: filename,
                           content_type: 'image/jpeg',
                           storage_filename: 'zozo',
                           yandex_token: token
    end

    it do
      expect(photo).to be_valid

      expect(photo.exif).to be_nil
      expect(photo.lat_long).to be_nil
      expect(photo.original_timestamp).to be_nil
    end
  end

  context 'when gps data with zeros' do
    let(:filename) { 'test5.jpg' }
    let(:photo) { build :photo, local_filename: filename, content_type: 'image/jpeg' }

    it do
      expect(photo).to be_valid

      expect(photo.original_timestamp).to eq Time.new(2019, 7, 20, 14, 17, 17)
      expect(photo.exif).to include('model' => 'Z00AD', 'make' => 'ASUS')
      expect(photo.lat_long).to be_nil

      expect(photo).to have_attributes(width: 4_096, height: 3_072)
    end
  end

  context 'when right top orientation' do
    let(:filename) { 'test6.jpg' }
    let(:photo) { build :photo, local_filename: filename, content_type: 'image/jpeg' }

    it do
      expect(photo).to be_valid

      expect(photo).to have_attributes(width: 3_072, height: 4_096)
      expect(photo.original_timestamp).to eq Time.new(2019, 7, 20, 12, 11, 33)
      expect(photo.exif).to include('model' => 'Z00AD', 'make' => 'ASUS')
      expect(photo.lat_long).to be_nil
    end
  end
end
