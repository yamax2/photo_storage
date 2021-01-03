# frozen_string_literal: true

RSpec.describe Rubrics::ListingFinder do
  # rubocop:disable RSpec/LetSetup
  subject(:listing) { described_class.call(rubric_id, opts) }

  let(:opts) { {} }
  let(:actual_models) { listing.group_by(&:model_type).transform_values! { |v| v.map(&:id) } }
  let(:token) { create :'yandex/token' }

  # not uploaded photo
  let!(:rubric1_empty) { create :rubric }

  # normal photo
  let!(:rubric2_with_photo_and_avatar) { create :rubric }

  # empty with sub_rubric
  let!(:rubric3_with_sub_rubrics) { create :rubric }
  let!(:rubric4_sub_and_empty) { create :rubric, rubric_id: rubric3_with_sub_rubrics }

  # uploaded photo and without avatar
  let!(:rubric5_without_avatar) { create :rubric }

  # uploaded photo only in sub_rubric
  let!(:rubric6_only_deep) { create :rubric }
  let!(:rubric7_sub) { create :rubric, rubric: rubric6_only_deep }

  # uploaded
  let!(:photo_for_rubric2) do
    create :photo, rubric: rubric2_with_photo_and_avatar, storage_filename: '1.jpg', yandex_token: token
  end

  # not uploaded
  let!(:photo_for_rubric1) { create :photo, rubric: rubric1_empty, local_filename: '1.jpg' }

  # uploaded deep
  let!(:photo_for_rubric7) { create :photo, rubric: rubric7_sub, storage_filename: '1.jpg', yandex_token: token }

  # uploaded without avatar
  let!(:photo_for_rubric5) do
    create :photo, rubric: rubric5_without_avatar, storage_filename: '1.jpg', yandex_token: token
  end

  before do
    rubric2_with_photo_and_avatar.update!(main_photo_id: photo_for_rubric2.id)
    rubric6_only_deep.update!(main_photo_id: photo_for_rubric7.id)
    rubric7_sub.update!(main_photo_id: photo_for_rubric7.id)
  end

  context 'when root rubric' do
    let(:rubric_id) { nil }

    it do
      expect(actual_models['Rubric']).
        to eq([rubric6_only_deep.id, rubric5_without_avatar.id, rubric2_with_photo_and_avatar.id, rubric1_empty.id])

      expect(listing.first).to have_attributes(
        id: rubric6_only_deep.id,
        name: rubric6_only_deep.name,
        yandex_token_id: photo_for_rubric7.yandex_token_id,
        storage_filename: photo_for_rubric7.storage_filename,
        model_type: 'Rubric',
        rubric_id: nil
      )

      expect(listing.second).to have_attributes(
        id: rubric5_without_avatar.id,
        name: rubric5_without_avatar.name,
        yandex_token_id: nil,
        storage_filename: nil,
        model_type: 'Rubric',
        rubric_id: nil
      )

      expect(listing.third).to have_attributes(
        id: rubric2_with_photo_and_avatar.id,
        name: rubric2_with_photo_and_avatar.name,
        yandex_token_id: photo_for_rubric2.yandex_token_id,
        storage_filename: photo_for_rubric2.storage_filename,
        model_type: 'Rubric',
        rubric_id: nil
      )

      expect(listing.last).to have_attributes(
        id: rubric1_empty.id,
        name: rubric1_empty.name,
        yandex_token_id: nil,
        storage_filename: nil,
        model_type: 'Rubric',
        rubric_id: nil
      )

      expect(actual_models).not_to include('Photo')
    end
  end

  context 'when empty' do # although visible in root
    let(:rubric_id) { rubric1_empty.id }

    it { is_expected.to be_empty }
  end

  context 'when with sub_rubrics and without photos' do
    let(:rubric_id) { rubric6_only_deep.id }

    it do
      expect(actual_models.keys).to match_array(%w[Rubric])
      expect(actual_models['Rubric']).to match_array([rubric7_sub.id])

      expect(listing.first).to have_attributes(
        id: rubric7_sub.id,
        name: rubric7_sub.name,
        storage_filename: photo_for_rubric7.storage_filename,
        model_type: 'Rubric',
        rubric_id: nil
      )
    end
  end

  context 'when with photos' do
    let(:rubric_id) { rubric2_with_photo_and_avatar.id }

    it do
      expect(actual_models.keys).to match_array(%w[Photo])
      expect(actual_models['Photo']).to match_array([photo_for_rubric2.id])

      expect(listing.first).to have_attributes(
        id: photo_for_rubric2.id,
        name: photo_for_rubric2.name,
        storage_filename: photo_for_rubric2.storage_filename,
        model_type: 'Photo',
        rubric_id: rubric2_with_photo_and_avatar.id
      )
    end
  end

  context 'when with rubrics and photos' do
    let!(:another_photo) { create :photo, rubric: rubric7_sub, storage_filename: '2.jpg', yandex_token: token }
    let!(:another_empty_rubric) { create :rubric, rubric: rubric7_sub }
    let!(:another_rubric) { create :rubric, rubric: rubric7_sub }

    let(:rubric_id) { rubric7_sub.id }

    before do
      create :photo, rubric: another_rubric, storage_filename: '3.jpg', yandex_token: token
      create :photo, rubric: another_rubric, local_filename: '4.jpg'
    end

    it do
      expect(actual_models.keys).to match_array(%w[Photo Rubric])

      expect(actual_models['Photo']).to match_array([photo_for_rubric7.id, another_photo.id])
      expect(actual_models['Rubric']).to match_array([another_rubric.id])
    end
  end

  context 'when wrong rubric' do
    let(:rubric_id) { -1 }

    it { is_expected.to be_empty }
  end

  context 'when only_with_geo_tags option for root' do
    let(:rubric_id) { nil }
    let(:opts) { {only_with_geo_tags: true} }

    it do
      expect { listing }.to raise_error(/only_with_geo_tags/)
    end
  end

  context 'when only_with_geo_tags option' do
    let(:rubric_id) { rubric6_only_deep.id }
    let(:opts) { {only_with_geo_tags: true} }

    let!(:another_photo) do
      create :photo, rubric: rubric6_only_deep, storage_filename: '2.jpg', yandex_token: token, lat_long: [1, 2]
    end

    before do
      create :photo, rubric: rubric6_only_deep, local_filename: '4.jpg', lat_long: [3, 4]
      create :photo, rubric: rubric6_only_deep, storage_filename: '1.jpg', yandex_token: token
    end

    it do
      expect(actual_models.keys).to match_array(%w[Photo])

      expect(actual_models['Photo']).to match_array([another_photo.id])
    end
  end

  context 'when pagination' do
    context 'when root' do
      let(:rubric_id) { nil }

      context 'when first 2 objects' do
        let(:opts) { {limit: 2} }

        it do
          expect(actual_models['Rubric']).to eq([rubric6_only_deep.id, rubric5_without_avatar.id])
          expect(actual_models).not_to include('Photo')
        end
      end

      context 'when last objects' do
        let(:opts) { {limit: 2, offset: 3} }

        it do
          expect(actual_models['Rubric']).to eq([rubric1_empty.id])
          expect(actual_models).not_to include('Photo')
        end
      end

      context 'when objects in the middle' do
        let(:opts) { {limit: 2, offset: 1} }

        it do
          expect(actual_models['Rubric']).to eq([rubric5_without_avatar.id, rubric2_with_photo_and_avatar.id])
          expect(actual_models).not_to include('Photo')
        end
      end

      context 'when offset without a limit' do
        let(:opts) { {offset: 1} }

        it do
          expect(actual_models['Rubric']).
            to eq([rubric5_without_avatar.id, rubric2_with_photo_and_avatar.id, rubric1_empty.id])
          expect(actual_models).not_to include('Photo')
        end
      end

      context 'when wrong offset' do
        let(:opts) { {offset: 500, limit: 2} }

        it { is_expected.to be_empty }
      end
    end

    context 'when rubrics and photos' do

    end
  end
  # rubocop:enable RSpec/LetSetup
end
