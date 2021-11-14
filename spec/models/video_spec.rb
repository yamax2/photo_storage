# frozen_string_literal: true

RSpec.describe Video do
  it_behaves_like 'storable model', :video
  it_behaves_like 'model with counter', :video

  describe 'structure' do
    let(:tz) { Rails.application.config.time_zone }

    it { is_expected.to have_db_column(:storage_filename).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:preview_filename).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:yandex_token_id).of_type(:integer).with_options(null: false) }

    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 512) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:rubric_id).of_type(:integer).with_options(null: false) }

    it { is_expected.to have_db_column(:lat_long).of_type(:point) }
    it { is_expected.to have_db_column(:original_timestamp).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:content_type).of_type(:string).with_options(null: false, limit: 30) }
    it { is_expected.to have_db_column(:width).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:height).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:views).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:tz).of_type(:string).with_options(null: false, limit: 50, default: tz) }
    it { is_expected.to have_db_column(:props).of_type(:jsonb).with_options(null: false, default: {}) }

    it { is_expected.to have_db_index(:rubric_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:yandex_token).inverse_of(:videos) }
    it { is_expected.to belong_to(:rubric).inverse_of(:videos).counter_cache(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(512) }

    it { is_expected.to validate_presence_of(:width) }
    it { is_expected.to validate_numericality_of(:width).is_greater_than(0).only_integer }

    it { is_expected.to validate_presence_of(:height) }
    it { is_expected.to validate_numericality_of(:height).is_greater_than(0).only_integer }

    it { is_expected.to validate_presence_of(:content_type) }
    it { is_expected.to validate_inclusion_of(:content_type).in_array(described_class::ALLOWED_CONTENT_TYPES) }

    it { is_expected.to validate_inclusion_of(:tz).in_array(Rails.application.config.photo_timezones) }

    it { is_expected.to validate_presence_of(:storage_filename) }
    it { is_expected.to validate_length_of(:storage_filename).is_at_most(512) }

    it { is_expected.to validate_presence_of(:preview_filename) }
    it { is_expected.to validate_length_of(:preview_filename).is_at_most(512) }
  end
end
