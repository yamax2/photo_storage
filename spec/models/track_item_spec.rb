# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrackItem do
  it_behaves_like 'storable model', :track_item

  describe 'structure' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 512) }
    it { is_expected.to have_db_column(:track_id).of_type(:integer).with_options(null: false, foreign_key: true) }

    it { is_expected.to have_db_column(:avg_speed).of_type(:decimal).with_options(null: false, default: 0.0) }
    it { is_expected.to have_db_column(:duration).of_type(:decimal).with_options(null: false, default: 0.0) }
    it { is_expected.to have_db_column(:distance).of_type(:decimal).with_options(null: false, default: 0.0) }

    it { is_expected.to have_db_index(:track_id) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(512) }

    it { is_expected.to validate_presence_of(:avg_speed) }
    it { is_expected.to validate_numericality_of(:avg_speed).is_greater_than_or_equal_to(0) }

    it { is_expected.to validate_presence_of(:duration) }
    it { is_expected.to validate_numericality_of(:duration).is_greater_than_or_equal_to(0) }

    it { is_expected.to validate_presence_of(:distance) }
    it { is_expected.to validate_numericality_of(:distance).is_greater_than_or_equal_to(0) }
  end

  describe 'strip attributes' do
    it { is_expected.to strip_attribute(:name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:yandex_token).inverse_of(:track_items).optional }
    it { is_expected.to belong_to(:track).inverse_of(:track_items) }
  end
end
