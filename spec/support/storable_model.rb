# frozen_string_literal: true

RSpec.shared_examples 'storable model' do
  describe 'structure' do
    it { is_expected.to have_db_column(:storage_filename).of_type(:text) }

    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }

    it { is_expected.to have_db_column(:size).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:md5).of_type(:string).with_options(null: false, limit: 32) }
    it { is_expected.to have_db_column(:sha256).of_type(:string).with_options(null: false, limit: 64) }
    it { is_expected.to have_db_column(:original_filename).of_type(:string).with_options(null: false, limit: 512) }
    it { is_expected.to have_db_column(:folder_index).of_type(:integer).with_options(null: false, default: 0) }

    it { is_expected.to have_db_index(:yandex_token_id) }
    it { is_expected.to have_db_index(%i[md5 sha256]).unique }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:md5) }
    it { is_expected.to validate_length_of(:md5).is_equal_to(32) }

    it { is_expected.to validate_presence_of(:sha256) }
    it { is_expected.to validate_length_of(:sha256).is_equal_to(64) }

    it { is_expected.to validate_presence_of(:original_filename) }
    it { is_expected.to validate_length_of(:original_filename).is_at_most(512) }

    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_numericality_of(:size).is_greater_than_or_equal_to(0).only_integer }
  end
end
