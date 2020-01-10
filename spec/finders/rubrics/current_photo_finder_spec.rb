# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rubrics::CurrentPhotoFinder do
  before { Timecop.freeze }
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

  subject { described_class.call(root_rubric1.id, photo_id) }

  context 'when first photo in listing' do
    let(:photo_id) { photo6.id }

    it do
      expect(subject.prev).to be_nil
      expect(subject.current).to eq(photo6)
      expect(subject.next).to eq(photo7)

      expect(subject.current.pos).to eq(1)
      expect(subject.next.pos).to eq(2)
    end
  end

  context 'when first photo with exif' do
    let(:photo_id) { photo3.id }

    it do
      expect(subject.prev).to eq(photo7)
      expect(subject.current).to eq(photo3)
      expect(subject.next).to eq(photo2)

      expect(subject.prev.pos).to eq(2)
      expect(subject.current.pos).to eq(3)
      expect(subject.next.pos).to eq(4)
    end
  end

  context 'when last photo in listing' do
    let(:photo_id) { photo5.id }

    it do
      expect(subject.prev).to eq(photo2)
      expect(subject.current).to eq(photo5)
      expect(subject.next).to be_nil

      expect(subject.prev.pos).to eq(4)
      expect(subject.current.pos).to eq(5)
    end
  end

  context 'when photo not in current rubric' do
    let(:photo_id) { photo1.id }

    it do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when wrong photo_id' do
    let(:photo_id) { -1 }

    it do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
