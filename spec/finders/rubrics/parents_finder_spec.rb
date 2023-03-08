# frozen_string_literal: true

RSpec.describe Rubrics::ParentsFinder do
  subject(:result) { described_class.call(rubric_id) }

  context 'when rubric without parent' do
    let(:rubric) { create :rubric }
    let(:rubric_id) { rubric.id }

    it { expect(result).to contain_exactly(rubric) }
  end

  context 'when rubric with a parent' do
    let(:rubric1) { create :rubric }
    let(:rubric2) { create :rubric, rubric: rubric1 }
    let(:rubric3) { create :rubric, rubric: rubric2 }

    let(:rubric_id) { rubric3.id }

    # wrong rubric
    before { create :rubric, rubric: rubric1 }

    it do
      expect(result).to eq([rubric3, rubric2, rubric1])
    end
  end

  context 'when non-existent rubric' do
    let(:rubric_id) { 100_500 }

    it { expect(result).to be_empty }
  end
end
