require 'rails_helper'

RSpec.describe City do
  describe 'structure' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 20) }
    it { is_expected.to have_db_column(:in_city_name).of_type(:string).with_options(limit: 50) }
    it { is_expected.to have_db_column(:domain).of_type(:string).with_options(null: false, limit: 15) }
    it { is_expected.to have_db_column(:active).of_type(:boolean).with_options(null: false, default: true) }

    it { is_expected.to have_db_column(:google_verification).of_type(:string).with_options(limit: 50) }
    it { is_expected.to have_db_column(:yandex_verification).of_type(:string).with_options(limit: 50) }

    it { is_expected.to have_db_index(:domain).unique(true) }

    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:domain) }

    it { is_expected.to validate_length_of(:name).is_at_most(20) }
    it { is_expected.to validate_length_of(:domain).is_at_most(15) }
    it { is_expected.to validate_length_of(:in_city_name).is_at_most(50) }
    it { is_expected.to validate_length_of(:google_verification).is_at_most(50) }
    it { is_expected.to validate_length_of(:yandex_verification).is_at_most(50) }

    it { is_expected.to strip_attribute(:name).collapse_spaces }
    it { is_expected.to strip_attribute(:domain).collapse_spaces }
  end

  describe 'domain normalization' do
    let(:city) { build :city, domain: domain }

    before { city.validate }

    subject { city.domain }

    context 'when upper case' do
      let(:domain) { 'EKB' }

      it { is_expected.to eq 'ekb' }
    end

    context 'when different case and spaces' do
      let(:domain) { '   eKb  ' }

      it { is_expected.to eq 'ekb' }
    end
  end
end
