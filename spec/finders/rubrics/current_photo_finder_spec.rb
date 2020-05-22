# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rubrics::CurrentPhotoFinder do
  subject(:result) { described_class.call(root_rubric1.id, photo_id) }

  before do
    Timecop.freeze

    # photo4
    create :photo, rubric: sub_rubric1,
                   storage_filename: 'test',
                   yandex_token: token,
                   original_timestamp: 4.days.ago
  end

  after { Timecop.return }

  let!(:root_rubric1) { create :rubric }
  let!(:sub_rubric1) { create :rubric, rubric: root_rubric1 }

  let(:token) { create :'yandex/token' }

  # photo6
  # photo7
  # photo3
  # photo2
  # photo5

  let!(:photo1) { create :photo, rubric: root_rubric1, local_filename: 'test', original_timestamp: 1.day.ago }

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

  context 'when first photo in listing' do
    let(:photo_id) { photo6.id }

    it do
      expect(result.prev).to be_nil
      expect(result.current).to eq(photo6)
      expect(result.next).to eq(photo7)

      expect(result.current.pos).to eq(1)
      expect(result.next.pos).to eq(2)
    end
  end

  context 'when first photo with exif' do
    let(:photo_id) { photo3.id }

    it do
      expect(result.prev).to eq(photo7)
      expect(result.current).to eq(photo3)
      expect(result.next).to eq(photo2)

      expect(result.prev.pos).to eq(2)
      expect(result.current.pos).to eq(3)
      expect(result.next.pos).to eq(4)
    end
  end

  context 'when last photo in listing' do
    let(:photo_id) { photo5.id }

    it do
      expect(result.prev).to eq(photo2)
      expect(result.current).to eq(photo5)
      expect(result.next).to be_nil

      expect(result.prev.pos).to eq(4)
      expect(result.current.pos).to eq(5)
    end
  end

  context 'when photo not in current rubric' do
    let(:photo_id) { photo1.id }

    it do
      expect { result }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when wrong photo_id' do
    let(:photo_id) { -1 }

    it do
      expect { result }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
