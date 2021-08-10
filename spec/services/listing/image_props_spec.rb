# frozen_string_literal: true

RSpec.describe Listing::ImageProps do
  subject(:props) { described_class.new(photo) }

  before do
    allow(Rails.application.config).to receive(:photo_sizes).and_return(
      thumb: ->(photo) { photo.width * 360 / photo.height },
      preview: 900
    )

    allow(Rails.application.config).to receive(:max_thumb_width).and_return(1_280)
  end

  describe '#image_size' do
    context 'when simple photo' do
      let(:photo) { create :photo, width: 1_000, height: 2_000, local_filename: 'test' }

      it do
        expect(props.image_size).to eq([180, 360])
        expect(props.image_size(:preview)).to eq([900, 1_800])
      end
    end

    context 'when wide photo' do
      let(:photo) { create :photo, width: 3_000, height: 300, local_filename: 'test' }

      it do
        expect(props.image_size).to eq([3_600, 360])
        expect(props.image_size(:preview)).to eq([900, 90])
      end
    end

    context 'when tiny photo' do
      let(:photo) { create :photo, width: 337, height: 225, local_filename: 'test' }

      it do
        expect(props.image_size).to eq([539, 359])
        expect(props.image_size(:preview)).to eq([337, 225])
      end
    end

    context 'when rotated 90 deg' do
      let(:photo) { create :photo, width: 5_152, height: 3_864, local_filename: 'test', rotated: 1 }

      it { expect(props.image_size).to eq([360, 270]) }
    end

    context 'when rotated 180 deg' do
      let(:photo) { create :photo, width: 5_152, height: 3_864, local_filename: 'test', rotated: 2 }

      it { expect(props.image_size).to eq([480, 360]) }
    end

    context 'when apply_rotation for 90 deg rotation' do
      let(:photo) { create :photo, width: 5_152, height: 3_864, local_filename: 'test', rotated: 1 }

      it { expect(props.image_size(apply_rotation: true)).to eq([270, 360]) }
    end

    context 'when apply_rotation for 180 deg rotation' do
      let(:photo) { create :photo, width: 5_152, height: 3_864, local_filename: 'test', rotated: 2 }

      it { expect(props.image_size(apply_rotation: true)).to eq([480, 360]) }
    end

    context 'when wrong size type' do
      let(:photo) { create :photo, width: 5_152, height: 3_864, local_filename: 'test' }

      it do
        expect { props.image_size(:wrong) }.to raise_error(KeyError)
      end
    end
  end

  describe '#css_transform' do
    let(:effects) { nil }
    let(:photo) do
      build :photo, width: 1_000, height: 2_000, local_filename: 'test', rotated: rotated, effects: effects
    end

    context 'when photo is not rotated and without effects' do
      let(:rotated) { nil }

      it { expect(props.css_transform).to be_nil }
    end

    shared_examples 'rotated_deg for rotated photo' do |value, deg|
      let(:rotated) { value }

      it { expect(props.css_transform).to eq("rotate(#{deg}deg)") }
    end

    it_behaves_like 'rotated_deg for rotated photo', 1, 90
    it_behaves_like 'rotated_deg for rotated photo', 2, 180
    it_behaves_like 'rotated_deg for rotated photo', 3, 270

    context 'when photo with effects and rotated' do
      let(:rotated) { 1 }
      let(:effects) { %w[scaleX(-1) scaleY(1)] }

      it do
        expect(props.css_transform).to include('rotate(90deg)', 'scaleX(-1)', 'scaleY(1)')
      end
    end
  end

  describe '#turned?' do
    let(:photo) { build :photo, width: 1_000, height: 2_000, local_filename: 'test', rotated: rotated }

    shared_examples 'turned? for photo' do |value, turned|
      let(:rotated) { value }

      it { expect(props.turned?).to eq(turned) }
    end

    it_behaves_like 'turned? for photo', nil, false
    it_behaves_like 'turned? for photo', 1, true
    it_behaves_like 'turned? for photo', 2, false
    it_behaves_like 'turned? for photo', 3, true
  end
end
