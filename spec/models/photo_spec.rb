# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Photo do
  it_behaves_like 'storable model', :photo
  it_behaves_like 'model with counter', :photo

  describe 'structure' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 512) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:rubric_id).of_type(:integer).with_options(null: false, foreign_key: true) }

    it { is_expected.to have_db_column(:exif).of_type(:jsonb) }
    it { is_expected.to have_db_column(:lat_long).of_type(:point) }
    it { is_expected.to have_db_column(:original_timestamp).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:content_type).of_type(:string).with_options(null: false, limit: 30) }
    it { is_expected.to have_db_column(:width).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:height).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:views).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:external_info).of_type(:text) }

    it do
      is_expected.to have_db_column(:tz).of_type(:string).with_options(
        null: false,
        default: Rails.application.config.time_zone,
        limit: 50
      )
    end

    it { is_expected.to have_db_index(:rubric_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:yandex_token).inverse_of(:photos).optional }
    it { is_expected.to belong_to(:rubric).inverse_of(:photos).counter_cache(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(512) }

    it { is_expected.to validate_presence_of(:width) }
    it { is_expected.to validate_numericality_of(:width).is_greater_than_or_equal_to(0).only_integer }

    it { is_expected.to validate_presence_of(:height) }
    it { is_expected.to validate_numericality_of(:height).is_greater_than_or_equal_to(0).only_integer }

    it { is_expected.to validate_presence_of(:content_type) }
    it { is_expected.to validate_inclusion_of(:content_type).in_array(described_class::ALLOWED_CONTENT_TYPES) }

    it { is_expected.to validate_inclusion_of(:tz).in_array(Rails.application.config.photo_timezones) }
  end

  describe 'strip attributes' do
    it { is_expected.to strip_attribute(:name) }
    it { is_expected.to strip_attribute(:description) }
    it { is_expected.to strip_attribute(:content_type) }
  end

  describe 'remote file removing' do
    let(:token) { create :'yandex/token' }
    let(:photo) { create :photo, local_filename: nil, storage_filename: 'zozo', yandex_token: token }

    it do
      expect(Photos::RemoveFileJob).to receive(:perform_async).with(token.id, 'zozo')

      expect { photo.destroy }.not_to raise_error
    end
  end

  describe 'position in cart' do
    before { allow(Cart::PhotoService).to receive(:call!) }

    let(:rubric) { create :rubric }
    let(:photo) { create :photo, local_filename: 'test', rubric: rubric }

    context 'when try to change name' do
      before do
        photo.name = photo.name + 'test'
        photo.save!
      end

      it do
        expect(Cart::PhotoService).not_to have_received(:call!)
      end
    end

    context 'when rubric changed' do
      let(:new_rubric) { create :rubric }

      before do
        photo.rubric = new_rubric
        photo.save!
      end

      it do
        expect(photo.rubric).to eq(new_rubric)
        expect(::Cart::PhotoService).
          to have_received(:call!).with(photo: photo, remove: true).once
      end
    end

    context 'when photo destroyed' do
      before { photo.destroy }

      it do
        expect(photo).not_to be_persisted
        expect(::Cart::PhotoService).
          to have_received(:call!).with(photo: photo, remove: true).once
      end
    end

    context 'when try to change rubric for a new photo' do
      let(:photo) { build :photo, local_filename: 'test', rubric: rubric }
      let(:new_rubric) { create :rubric }

      before do
        photo.rubric = new_rubric
        photo.save!
      end

      it do
        expect(photo.rubric).to eq(new_rubric)
        expect(Cart::PhotoService).not_to have_received(:call!)
      end
    end
  end

  describe 'rubric changing' do
    let(:old_rubric) { create :rubric }
    let(:new_rubric) { create :rubric }

    context 'when photo is persisted' do
      let(:photo) { create :photo, local_filename: 'test', rubric: old_rubric }

      before do
        Rubric.where(id: old_rubric.id).update_all(main_photo_id: photo.id)
      end

      it do
        expect { photo.update!(rubric: new_rubric) }.to change { old_rubric.reload.main_photo }.from(photo).to(nil)
      end
    end

    context 'when photo is not persisted' do
      let(:photo) { build :photo, local_filename: 'test', rubric: old_rubric }

      subject do
        photo.rubric = new_rubric
        photo.save!
      end

      it do
        expect(::Photos::ChangeMainPhotoService).not_to receive(:call!)

        expect { subject }.to change { photo.rubric }.from(old_rubric).to(new_rubric)
      end
    end
  end
end
