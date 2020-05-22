# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rubrics::PhotosFinder do
  before do
    Timecop.freeze

    # photo1
    create :photo, rubric: root_rubric1, local_filename: 'test', original_timestamp: 1.day.ago
  end

  after { Timecop.return }

  let!(:root_rubric1) { create :rubric }
  let!(:sub_rubric1) { create :rubric, rubric: root_rubric1 }
  let!(:sub_rubric2) { create :rubric, rubric: root_rubric1 }

  let(:token) { create :'yandex/token' }

  # photo6
  # photo7
  # photo3
  # photo2
  # photo5

  let!(:photo2) do
    create :photo, rubric: root_rubric1,
                   storage_filename: 'test',
                   yandex_token: token,
                   original_timestamp: 2.days.ago
  end

  let!(:photo3) do
    create :photo, rubric: root_rubric1,
                   storage_filename: 'test',
                   yandex_token: token,
                   original_timestamp: 3.days.ago
  end

  let!(:photo4) do
    create :photo, rubric: sub_rubric1,
                   storage_filename: 'test',
                   yandex_token: token,
                   original_timestamp: 4.days.ago
  end

  let!(:photo5) do
    create :photo, rubric: root_rubric1,
                   storage_filename: 'test',
                   yandex_token: token,
                   original_timestamp: 2.days.ago,
                   tz: 'Europe/Moscow'
  end

  let!(:photo6) do
    create :photo, rubric: root_rubric1,
                   storage_filename: 'test',
                   yandex_token: token,
                   original_timestamp: nil
  end

  let!(:photo7) do
    create :photo, rubric: root_rubric1,
                   storage_filename: 'test',
                   yandex_token: token,
                   original_timestamp: nil,
                   lat_long: [1, 2]
  end

  context 'when root rubric' do
    subject(:photos) { described_class.call(root_rubric1.id) }

    it do
      expect(photos).to eq([photo6, photo7, photo3, photo2, photo5])
      expect(photos.map(&:rn)).to eq([1, 2, 3, 4, 5])
    end
  end

  context 'when sub_rubric' do
    subject(:photos) { described_class.call(sub_rubric1.id) }

    it do
      expect(photos).to eq([photo4])
      expect(photos.map(&:rn)).to eq([1])
    end
  end

  context 'only_with_geo_tags opt' do
    subject(:photos) { described_class.call(root_rubric1.id, only_with_geo_tags: true) }

    it do
      expect(photos).to eq([photo7])
      expect(photos.map(&:rn)).to eq([1])
    end
  end

  context 'when pagination' do
    context 'and first 2 photos' do
      subject(:photos) { described_class.call(root_rubric1.id, limit: 2) }

      it do
        expect(photos).to eq([photo6, photo7])
        expect(photos.map(&:rn)).to eq([1, 2])
      end
    end

    context 'and last 2 photos' do
      subject(:photos) { described_class.call(root_rubric1.id, limit: 2, offset: 3) }

      it do
        expect(photos).to eq([photo2, photo5])
        expect(photos.map(&:rn)).to eq([4, 5])
      end
    end

    context 'and 3 photos in the middle' do
      subject(:photos) { described_class.call(root_rubric1.id, limit: 3, offset: 1) }

      it do
        expect(photos).to eq([photo7, photo3, photo2])
        expect(photos.map(&:rn)).to eq([2, 3, 4])
      end
    end

    context 'and offset without limit' do
      subject(:photos) { described_class.call(root_rubric1.id, offset: 1) }

      it do
        expect(photos.map(&:rn)).to eq([2, 3, 4, 5])
      end
    end

    context 'and only_with_geo_tags' do
      subject(:photos) { described_class.call(root_rubric1.id, offset: 1, limit: 5, only_with_geo_tags: true) }

      it do
        expect(photos).to be_empty
      end
    end
  end

  context 'when wrong rubric' do
    subject(:photos) { described_class.call(-1) }

    it { is_expected.to be_empty }
  end

  context 'when rubric without photos' do
    subject(:photos) { described_class.call(sub_rubric2.id) }

    it { is_expected.to be_empty }
  end
end
