# frozen_string_literal: true

RSpec.describe ReportQuery do
  describe '.allowed_reports' do
    subject(:report) { described_class.allowed_reports }

    it { is_expected.to match_array(%i[cameras]) }
  end

  context 'when try to create with a wrong report type' do
    it do
      expect { described_class.new(:wrong) }.to raise_error(/Unknown report type/)
    end
  end

  describe 'cameras report' do
    subject(:cameras) { described_class.new(:cameras).to_a }

    context 'when without any data' do
      it { is_expected.to be_empty }
    end

    context 'when some photos' do
      before do
        create_list :photo, 10, exif: {make: 'some', model: '1'}, local_filename: '1.jpg'
        create :photo, exif: {}, local_filename: '1.jpg'
        create :photo, exif: {make: 'some'}, local_filename: '1.jpg'
        create_list :photo, 5, exif: {make: 'other', model: '2'}, local_filename: '1.jpg'
      end

      it do
        expect(cameras).to eq(
          [
            {'camera' => 'SOME 1', 'count' => 10},
            {'camera' => 'OTHER 2', 'count' => 5},
            {'camera' => 'Прочее', 'count' => 2}
          ]
        )
      end
    end
  end
end
