# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Track do
  describe 'structure' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 512) }

    it { is_expected.to have_db_column(:rubric_id).of_type(:integer).with_options(null: false, foreign_key: true) }
    it { is_expected.to have_db_index(:rubric_id) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(512) }
  end

  describe 'strip attributes' do
    it { is_expected.to strip_attribute(:name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:rubric).inverse_of(:tracks) }
    it { is_expected.to have_many(:track_items).inverse_of(:track).dependent(:destroy) }
  end
end
