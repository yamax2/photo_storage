# frozen_string_literal: true

RSpec.describe RubricDecorator do
  describe '#main_photo' do
    subject(:result) { rubric.decorate.main_photo }

    context 'when rubric with main_photo' do
      let(:main_photo) { create :photo, local_filename: 'test' }
      let(:rubric) { create :rubric, main_photo: main_photo }

      it { expect(result.object).to eq(main_photo) }
    end

    context 'when rubric without main_photo' do
      let(:rubric) { create :rubric, main_photo: nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#rubric_name' do
    subject { rubric.decorate.rubric_name }

    context 'when without photos and rubrics' do
      let(:rubric) { create :rubric, name: 'test' }

      it { is_expected.to eq('test') }
    end

    context 'when with photos' do
      let(:rubric) { create :rubric, name: 'test', photos_count: 10 }

      it { is_expected.to eq('test, фото: 10') }
    end

    context 'when with rubrics' do
      let(:rubric) { create :rubric, name: 'test', rubrics_count: 5 }

      it { is_expected.to eq('test, подрубрик: 5') }
    end

    context 'when with photos and rubrics' do
      let(:rubric) { create :rubric, name: 'test', rubrics_count: 5, photos_count: 10 }

      it { is_expected.to eq('test, подрубрик: 5, фото: 10') }
    end
  end

  describe '#rubrics_tree' do
    subject(:decorated_rubric) { rubric3.decorate }

    let(:rubric1) { create :rubric }
    let(:rubric2) { create :rubric, rubric: rubric1 }
    let(:rubric3) { create :rubric, rubric: rubric2 }

    it { expect(decorated_rubric.rubrics_tree).to eq([rubric3, rubric2, rubric1]) }
  end
end
