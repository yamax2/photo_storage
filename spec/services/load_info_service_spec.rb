require 'rails_helper'

RSpec.describe Yandex::LoadInfoService do
  let(:photo) { create :photo, local_filename: filename }

  before do
    Timecop.freeze Time.new(2019, 06, 16, 13, 8, 32)

    FileUtils.mkdir_p(Rails.root.join('tmp', 'files'))
    FileUtils.cp("spec/fixtures/#{filename}", Rails.root.join('tmp', 'files', filename))
  end

  after do
    FileUtils.rm_f Rails.root.join('tmp', 'files', filename)

    Timecop.return
  end

  context 'when correct jpg image' do
    before do
      described_class.call!(photo: photo)

      photo.reload
    end

    context 'when Huawei photo' do
      let(:filename) { 'test1.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'CLT-L29', 'make' => 'HUAWEI')
        expect(photo.lat_long.to_a).to eq([56.4737777708333, 58.1308860777778])
        expect(photo.original_timestamp).to eq(Time.new(2019, 6, 15, 21, 43, 32))
      end
    end

    context 'when HighScreen photo' do
      let(:filename) { 'test2.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'FestXL', 'make' => 'HighScreen')
        expect(photo.lat_long.to_a).to eq([56.0975074722222, 49.8604278333333])
        expect(photo.original_timestamp).to eq(Time.new(2019, 5, 2, 18, 40, 53))
      end
    end

    context 'when asus photo' do
      let(:filename) { 'test3.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to include('model' => 'ZB602KL', 'make' => 'asus')
        expect(photo.lat_long.to_a).to eq([59.2284763888889, 56.8072841944444])
        expect(photo.original_timestamp).to eq(Time.new(2019, 5, 28, 18, 22, 10))
      end
    end

    context 'when jpeg without exif' do
      let(:filename) { 'cats.jpg' }

      it do
        expect(photo).to be_valid

        expect(photo.exif).to be_nil
        expect(photo.lat_long).to be_nil
        expect(photo.original_timestamp).to eq(Time.current)
      end
    end
  end

  context 'when png image' do
    let(:filename) { 'cat.png' }
    let(:photo) { create :photo, local_filename: filename, content_type: 'image/png' }

    it do
      expect(photo).to be_valid

      expect(photo.exif).to be_nil
      expect(photo.lat_long).to be_nil
      expect(photo.original_timestamp).to eq(Time.current)
    end
  end

  context 'when info already loaded' do
    let(:filename) { 'test2.jpg' }
    let(:photo) { create :photo, exif: {} }

    it do
      expect(photo).to be_valid
      expect(photo.exif).to be_empty
      expect(photo.lat_long).to be_nil
      expect(photo.original_timestamp).to eq(Time.current)
    end
  end
end
