require 'rails_helper'

RSpec.describe Photo do
  describe 'structure' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 512) }
    it { is_expected.to have_db_column(:description).of_type(:text) }

    it { is_expected.to have_db_column(:rubric_id).of_type(:integer).with_options(null: true, foreign_key: true) }
    it { is_expected.to have_db_column(:yandex_token_id).of_type(:integer).with_options(null: true, foreign_key: true) }

    it { is_expected.to have_db_column(:storage_filename).of_type(:text) }
    it { is_expected.to have_db_column(:local_filename).of_type(:text) }

    it { is_expected.to have_db_column(:exif).of_type(:jsonb) }
    it { is_expected.to have_db_column(:lat_long).of_type(:point) }
    it { is_expected.to have_db_column(:original_filename).of_type(:string).with_options(null: false, limit: 512) }
    it { is_expected.to have_db_column(:original_timestamp).of_type(:datetime) }
    it { is_expected.to have_db_column(:size).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:content_type).of_type(:string).with_options(null: false, limit: 30) }
    it { is_expected.to have_db_column(:width).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:height).of_type(:integer).with_options(null: false, default: 0) }

    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }

    it { is_expected.to have_db_index(:rubric_id) }
    it { is_expected.to have_db_index(:yandex_token_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:rubric).inverse_of(:photos) }
    it { is_expected.to belong_to(:yandex_token).inverse_of(:photos) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(512) }

    it { is_expected.to validate_presence_of(:original_filename) }
    it { is_expected.to validate_length_of(:original_filename).is_at_most(512) }

    it { is_expected.to validate_presence_of(:width) }
    it { is_expected.to validate_numericality_of(:width).is_greater_than_or_equal_to(0).only_integer }

    it { is_expected.to validate_presence_of(:height) }
    it { is_expected.to validate_numericality_of(:height).is_greater_than_or_equal_to(0).only_integer }

    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_numericality_of(:size).is_greater_than_or_equal_to(0).only_integer }

    it { is_expected.to validate_presence_of(:content_type) }
    it { is_expected.to validate_inclusion_of(:content_type).in_array(described_class::ALLOWED_CONTENT_TYPES) }
  end

  describe 'upload status validation' do
    context 'when both attributes present' do
      subject { build :photo, storage_filename: 'zozo', local_filename: 'test' }

      it do
        is_expected.not_to be_valid
        expect(subject.errors).to include(:local_filename)
      end
    end

    context 'when storage_filename presents' do
      subject { build :photo, storage_filename: 'zozo', local_filename: nil }

      it { is_expected.to be_valid }
    end

    context 'when local_filename presents' do
      subject { build :photo, storage_filename: nil, local_filename: 'test' }

      it { is_expected.to be_valid }
    end

    context 'when both attributes empty' do
      subject { build :photo, storage_filename: nil, local_filename: nil }

      it { is_expected.to be_valid }
    end
  end

  describe 'strip attributes' do
    it { is_expected.to strip_attribute(:name) }
    it { is_expected.to strip_attribute(:description) }
    it { is_expected.to strip_attribute(:content_type) }
  end

  describe '#original_timestamp' do
    before { Timecop.freeze }
    after { Timecop.return }

    before { subject.validate }

    context 'when empty value' do
      subject { build :photo, created_at: 10.days.ago }

      it do
        expect(subject.original_timestamp).to eq(Time.current)
      end
    end

    context 'when non-empty value' do
      subject { build :photo, created_at: 10.days.ago, original_timestamp: 20.days.ago }

      it do
        expect(subject.original_timestamp).to eq(20.days.ago)
      end
    end
  end

  describe 'scopes' do
    let!(:uploaded) { create_list :photo, 2, storage_filename: 'test' }
    let!(:pending) { create_list :photo, 2, local_filename: 'zozo' }

    describe '#uploaded' do
      it { expect(described_class.uploaded).to match_array(uploaded) }
    end

    describe '#pending' do
      it { expect(described_class.pending).to match_array(pending) }
    end
  end
end
