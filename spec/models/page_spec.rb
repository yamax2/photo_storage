require 'rails_helper'

RSpec.describe Page do
  let!(:root_rubric1) { create :rubric }
  let!(:root_rubric2) { create :rubric }

  let!(:sub_rubric1) { create :rubric, rubric: root_rubric1 }
  let!(:sub_rubric2) { create :rubric, rubric: root_rubric1 }

  let(:token) { create :'yandex/token' }

  let!(:photo1) { create :photo, :fake, rubric: root_rubric1, local_filename: 'test' }
  let!(:photo2) { create :photo, :fake, rubric: root_rubric1, storage_filename: 'test', yandex_token: token }
  let!(:photo3) { create :photo, :fake, rubric: root_rubric1, storage_filename: 'test', yandex_token: token }
  let!(:photo4) { create :photo, :fake, rubric: sub_rubric1, storage_filename: 'test', yandex_token: token }

  context 'when page is root' do
    subject { Page.new }

    it do
      expect(subject.rubric).to be_nil
      expect(subject.rubrics).to match_array([root_rubric1])
      expect(subject.photos).to be_empty
    end
  end

  context 'when page is rubric' do
    context 'and root rubric' do
      subject { Page.new(root_rubric1.id) }

      it do
        expect(subject.rubric.object).to eq(root_rubric1)
        expect(subject.rubrics).to match_array([sub_rubric1])
        expect(subject.photos).to match_array([photo2, photo3])
      end
    end

    context 'and sub_rubric' do
      subject { Page.new(sub_rubric1.id) }

      it do
        expect(subject.rubric.object).to eq(sub_rubric1)
        expect(subject.rubrics).to be_empty
        expect(subject.photos).to match_array([photo4])
        expect(subject.rubrics_tree).to eq([sub_rubric1, root_rubric1])
      end
    end
  end
end
