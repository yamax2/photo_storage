require 'rails_helper'

RSpec.describe Yandex::Token do
  describe 'structure' do
    it { is_expected.to have_db_column(:user_id).of_type(:string).with_options(null: false, limit: 20) }
    it { is_expected.to have_db_column(:login).of_type(:string).with_options(null: false, limit: 255) }

    it { is_expected.to have_db_column(:access_token).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:valid_till).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:refresh_token).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:token_type).of_type(:string).with_options(null: false, limit: 20) }

    it { is_expected.to have_db_column(:dir).of_type(:string).with_options(limit: 255) }
    it { is_expected.to have_db_column(:other_dir).of_type(:string).with_options(limit: 255) }

    it { is_expected.to have_db_column(:active).of_type(:boolean).with_options(default: false) }
    it { is_expected.to have_db_column(:used_space).of_type(:integer).with_options(default: 0, null: false) }
    it { is_expected.to have_db_column(:total_space).of_type(:integer).with_options(default: 0, null: false) }

    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_length_of(:user_id).is_at_most(20) }

    it { is_expected.to validate_presence_of(:login) }
    it { is_expected.to validate_length_of(:login).is_at_most(255) }

    it { is_expected.to validate_presence_of(:access_token) }
    it { is_expected.to validate_length_of(:access_token).is_at_most(100) }

    it { is_expected.to validate_presence_of(:refresh_token) }
    it { is_expected.to validate_length_of(:refresh_token).is_at_most(100) }

    it { is_expected.to validate_presence_of(:valid_till) }

    it { is_expected.to validate_presence_of(:token_type) }
    it { is_expected.to validate_length_of(:token_type).is_at_most(20) }

    it { is_expected.to validate_length_of(:dir).is_at_most(255) }
    it { is_expected.to validate_length_of(:other_dir).is_at_most(255) }

    it { is_expected.to validate_presence_of(:used_space) }
    it { is_expected.to validate_presence_of(:total_space) }
  end

  describe 'active prop validation' do
    context 'when active' do
      subject { build :'yandex/token', active: true }

      it { is_expected.to validate_presence_of(:dir) }
      it { is_expected.to validate_presence_of(:other_dir) }
    end

    context 'when inactive' do
      subject { build :'yandex/token', active: false }

      it { is_expected.not_to validate_presence_of(:dir) }
      it { is_expected.not_to validate_presence_of(:other_dir) }
    end
  end
end
