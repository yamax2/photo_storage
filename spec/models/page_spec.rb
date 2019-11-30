# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Page do
  before { Timecop.freeze }
  after { Timecop.return }

  let!(:root_rubric1) { create :rubric }
  let!(:root_rubric2) { create :rubric }

  let!(:sub_rubric1) { create :rubric, rubric: root_rubric1 }
  let!(:sub_rubric2) { create :rubric, rubric: root_rubric1 }

  let(:token) { create :'yandex/token' }

  # photo6
  # photo7
  # photo3
  # photo2
  # photo5

  let!(:photo1) { create :photo, :fake, rubric: root_rubric1, local_filename: 'test', original_timestamp: 1.day.ago }

  let!(:photo2) do
    create :photo, :fake, rubric: root_rubric1,
                          storage_filename: 'test',
                          yandex_token: token,
                          original_timestamp: 2.days.ago
  end

  let!(:photo3) do
    create :photo, :fake, rubric: root_rubric1,
                          storage_filename: 'test',
                          yandex_token: token,
                          original_timestamp: 3.days.ago
  end

  let!(:photo4) do
    create :photo, :fake, rubric: sub_rubric1,
                          storage_filename: 'test',
                          yandex_token: token,
                          original_timestamp: 4.days.ago
  end

  let!(:photo5) do
    create :photo, :fake, rubric: root_rubric1,
                          storage_filename: 'test',
                          yandex_token: token,
                          original_timestamp: 2.days.ago,
                          tz: 'Europe/Moscow'
  end

  let!(:photo6) do
    create :photo, :fake, rubric: root_rubric1,
                          storage_filename: 'test',
                          yandex_token: token,
                          original_timestamp: nil
  end

  let!(:photo7) do
    create :photo, :fake, rubric: root_rubric1,
                          storage_filename: 'test',
                          yandex_token: token,
                          original_timestamp: nil
  end

  context 'when page is root' do
    subject { Page.new }

    it do
      expect(subject.rubric).to be_nil
      expect(subject.rubrics.map(&:object)).to match_array([root_rubric1])
      expect(subject.photos).to be_empty
    end
  end

  context 'when page is rubric' do
    context 'and root rubric' do
      subject { Page.new(root_rubric1.id) }

      it do
        expect(subject.rubric.object).to eq(root_rubric1)
        expect(subject.rubrics.map(&:object)).to match_array([sub_rubric1])

        expect(subject.photos.map(&:object)).to eq([photo6, photo7, photo3, photo2, photo5])
        expect(subject.photos.map(&:rn)).to eq([1, 2, 3, 4, 5])
      end
    end

    context 'and sub_rubric' do
      subject { Page.new(sub_rubric1.id) }

      it do
        expect(subject.rubric.object).to eq(sub_rubric1)
        expect(subject.rubrics).to be_empty
        expect(subject.photos).to match_array([photo4])
        expect(subject.photos.first.rn).to eq(1)
        expect(subject.rubrics_tree).to eq([sub_rubric1, root_rubric1])
      end
    end

    context 'when pagination' do
      context 'and first 2 photos' do
        subject { Page.new(root_rubric1.id, offset: 0, limit: 2) }

        it do
          expect(subject.photos.map(&:rn)).to eq([1, 2])
          expect(subject.photos.map(&:object)).to eq([photo6, photo7])
        end
      end

      context 'and last 2 photos' do
        subject { Page.new(root_rubric1.id, offset: 3, limit: 2) }

        it do
          expect(subject.photos.map(&:rn)).to eq([4, 5])
          expect(subject.photos.map(&:object)).to eq([photo2, photo5])
        end
      end

      context 'and 3 photos in the middle' do
        subject { Page.new(root_rubric1.id, offset: 1, limit: 3) }

        it do
          expect(subject.photos.map(&:rn)).to eq([2, 3, 4])
          expect(subject.photos.map(&:object)).to eq([photo7, photo3, photo2])
        end
      end

      context 'and offset without limit' do
        subject { Page.new(root_rubric1.id, offset: 1) }

        it do
          expect(subject.photos.map(&:rn)).to eq([1, 2, 3, 4, 5])
        end
      end
    end
  end

  describe '#find_photo_with_next_and_prev' do
    let(:page) { Page.new(root_rubric1.id) }

    subject { page.find_photo_with_next_and_prev(photo_id) }

    context 'and first photo in listing' do
      let(:photo_id) { photo6.id }

      it do
        expect(subject.prev).to be_nil
        expect(subject.current).to eq(photo6)
        expect(subject.next).to eq(photo7)

        expect(subject.current.pos).to eq(1)
        expect(subject.next.pos).to eq(2)
      end
    end

    context 'and first photo with exif' do
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

    context 'and last photo in listing' do
      let(:photo_id) { photo5.id }

      it do
        expect(subject.prev).to eq(photo2)
        expect(subject.current).to eq(photo5)
        expect(subject.next).to eq(nil)

        expect(subject.prev.pos).to eq(4)
        expect(subject.current.pos).to eq(5)
      end
    end

    context 'and photo not in current rubric' do
      let(:photo_id) { photo1.id }

      it do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#with_rubrics?' do
    subject { Page.new(rubric_id).with_rubrics? }

    context 'when root' do
      let(:rubric_id) { nil }

      it { is_expected.to eq(true) }
    end

    context 'when rubric without subrubrics' do
      let(:rubric_id) { root_rubric2.id }

      it { is_expected.to eq(false) }
    end

    context 'when rubric with subrubrics and photos but without counter' do
      let(:rubric_id) { root_rubric1.id }

      before do
        Rubric.where(id: root_rubric1.id).update_all(rubrics_count: 0)
      end

      it { is_expected.to eq(false) }
    end

    context 'when rubric with subrubrics but without photos' do
      let(:rubric_id) { root_rubric2.id }
      let!(:test_rubric) { create :rubric, rubric: root_rubric2 }

      it { is_expected.to eq(false) }
    end

    context 'when rubric with subrubrics and photos' do
      let(:rubric_id) { root_rubric1.id }

      it { is_expected.to eq(true) }
    end
  end
end
