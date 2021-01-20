# frozen_string_literal: true

RSpec.describe Yandex::Token do
  describe 'structure' do
    it { is_expected.to have_db_column(:user_id).of_type(:string).with_options(null: false, limit: 20) }
    it { is_expected.to have_db_column(:login).of_type(:string).with_options(null: false, limit: 255) }

    it { is_expected.to have_db_column(:access_token).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:valid_till).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:refresh_token).of_type(:string).with_options(null: false, limit: 100) }

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

    it { is_expected.to validate_length_of(:dir).is_at_most(255) }
    it { is_expected.to validate_length_of(:other_dir).is_at_most(255) }

    it { is_expected.to validate_presence_of(:used_space) }
    it { is_expected.to validate_presence_of(:total_space) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:photos).inverse_of(:yandex_token).dependent(:destroy) }
    it { is_expected.to have_many(:tracks).inverse_of(:yandex_token).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:token1) { create :'yandex/token', active: true }
    let!(:token2) { create :'yandex/token', active: true }

    before { create :'yandex/token', active: false }

    it do
      expect(described_class.active).to eq([token1, token2])
    end
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

  describe 'dir validations' do
    shared_examples 'dir validation' do |dir_attr|
      let(:token) { build :'yandex/token', active: false }

      context 'when valid' do
        before { token[dir_attr] = '/photos' }

        it { expect(token).to be_valid }
      end

      context 'when invalid' do
        before { token[dir_attr] = 'zozo' }

        it do
          expect(token).not_to be_valid
          expect(token.errors).to include(dir_attr)
        end
      end

      context 'when nil' do
        before { token[dir_attr] = nil }

        it { expect(token).to be_valid }
      end

      context 'when empty' do
        before { token[dir_attr] = '    ' }

        it { expect(token).to be_valid }
      end
    end

    it_behaves_like 'dir validation', :dir
    it_behaves_like 'dir validation', :other_dir
  end

  describe 'strip attributes' do
    it { is_expected.to strip_attribute(:dir) }
    it { is_expected.to strip_attribute(:other_dir) }
  end

  describe 'ransack' do
    subject(:scope) { described_class.ransack(s: 'free_space desc').result.to_a }

    let!(:token1) { create :'yandex/token', total_space: 30.megabytes, used_space: 15.megabytes }
    let!(:token2) { create :'yandex/token', total_space: 20.megabytes }

    it { is_expected.to eq([token2, token1]) }
  end
end
