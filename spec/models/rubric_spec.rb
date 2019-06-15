require 'rails_helper'

RSpec.describe Rubric do
  describe 'structure' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:description).of_type(:text) }

    it { is_expected.to have_db_column(:rubric_id).of_type(:integer).with_options(null: true, foreign_key: true) }

    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }

    it { is_expected.to have_db_index(:rubric_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:rubric).inverse_of(:rubrics).optional }
    it { is_expected.to have_many(:rubrics).inverse_of(:rubric).dependent(:destroy) }
    it { is_expected.to have_many(:photos).inverse_of(:rubric).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
  end

  describe 'strip attributes' do
    it { is_expected.to strip_attribute(:name) }
    it { is_expected.to strip_attribute(:description) }
  end
end
