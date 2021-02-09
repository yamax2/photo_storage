# frozen_string_literal: true

RSpec.describe Track do
  it_behaves_like 'storable model', :track

  describe 'structure' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 512) }

    it { is_expected.to have_db_column(:duration).of_type(:decimal).with_options(null: false, default: 0.0) }
    it { is_expected.to have_db_column(:distance).of_type(:decimal).with_options(null: false, default: 0.0) }
    it { is_expected.to have_db_column(:started_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:finished_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:bounds).of_type(:point).with_options(null: false, default: []) }

    it { is_expected.to have_db_column(:rubric_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_index(:rubric_id) }

    it { is_expected.to have_db_column(:color).of_type(:text).with_options(null: false, default: 'red') }
    it { is_expected.to have_db_column(:external_info).of_type(:text) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(512) }

    it { is_expected.to validate_presence_of(:duration) }
    it { is_expected.to validate_numericality_of(:duration).is_greater_than_or_equal_to(0) }

    it { is_expected.to validate_presence_of(:distance) }
    it { is_expected.to validate_numericality_of(:distance).is_greater_than_or_equal_to(0) }

    it { is_expected.to validate_presence_of(:color) }
  end

  describe 'bounds validation' do
    context 'when track is unpublished' do
      let(:track) { build :track, local_filename: 'test', bounds: [] }

      it do
        expect(track).to be_valid
      end
    end

    context 'when track is published' do
      let(:token) { create :'yandex/token' }
      let(:track) { build :track, storage_filename: 'test', bounds: bounds, yandex_token: token }

      context 'when empty bounds' do
        let(:bounds) { [] }

        it do
          expect(track.bounds.size).to eq(0)
          expect(track).not_to be_valid
          expect(track.errors).to include(:bounds)
        end
      end

      context 'when 1 item' do
        let(:bounds) { [ActiveRecord::Point.new(1, 2)] }

        it do
          expect(track.bounds.size).to eq(1)
          expect(track).not_to be_valid
          expect(track.errors).to include(:bounds)
        end
      end

      context 'when 2 items' do
        let(:bounds) { [ActiveRecord::Point.new(1, 2), ActiveRecord::Point.new(1, 2)] }

        it do
          expect(track.bounds.size).to eq(2)
          expect(track).to be_valid
        end
      end

      context 'when 3 items' do
        let(:bounds) { [ActiveRecord::Point.new(1, 2), ActiveRecord::Point.new(1, 2), ActiveRecord::Point.new(1, 2)] }

        it do
          expect(track.bounds.size).to eq(3)
          expect(track).not_to be_valid
          expect(track.errors).to include(:bounds)
        end
      end

      context 'when wrong array items' do
        let(:bounds) { [[1, 2], [3, 4]] }

        it do
          expect(track).not_to be_valid
          expect(track.errors).to include(:bounds)
        end
      end
    end
  end

  describe 'strip attributes' do
    it { is_expected.to strip_attribute(:name) }
    it { is_expected.to strip_attribute(:color) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:yandex_token).inverse_of(:tracks).optional }
    it { is_expected.to belong_to(:rubric).inverse_of(:tracks).counter_cache(true) }
  end

  describe 'remote file removing' do
    let(:token) { create :'yandex/token' }
    let(:track) { create :track, local_filename: nil, storage_filename: 'zozo', yandex_token: token }

    it do
      expect(Tracks::RemoveFileJob).to receive(:perform_async).with(token.id, 'zozo')

      expect { track.destroy }.not_to raise_error
    end
  end

  describe '.available_colors' do
    subject(:colors) { described_class.available_colors }

    it do
      expect(colors).to be_a(Array)
      expect(colors).to include('blue', 'red', 'green')
    end
  end

  describe '#avg_speed' do
    subject(:avg_speed) { track.avg_speed }

    context 'when duration is zero' do
      let(:track) { create :track, local_filename: 'test.gpx', duration: 0 }

      it { is_expected.to be_zero }
    end

    context 'when duration is assigned' do
      let(:track) { create :track, local_filename: 'test.gpx', duration: 7200, distance: 10 }

      it { is_expected.to eq(5) }
    end
  end
end
