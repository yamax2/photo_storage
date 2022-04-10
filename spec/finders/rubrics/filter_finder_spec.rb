# frozen_string_literal: true

RSpec.describe Rubrics::FilterFinder do
  subject(:result) { described_class.call(name_part:) }

  let!(:rubric1) { create :rubric, name: 'my first root rubric' }
  let!(:rubric2) { create :rubric, name: 'my second root rubric' }
  let!(:sub_rubric) { create :rubric, rubric: rubric1, name: 'my first sub_rubric' }
  let!(:deep_sub_rubric) { create :rubric, rubric: sub_rubric, name: 'my deep rubric' }

  context 'when nil argument' do
    let(:name_part) { nil }

    it { expect(result).to match_array(Rubric.all) }
  end

  context 'when empty argument' do
    let(:name_part) { '' }

    it { expect(result).to match_array(Rubric.all) }
  end

  context 'when search for root rubrics' do
    let(:name_part) { 'root' }

    it { expect(result).to match_array([rubric1, rubric2]) }
  end

  context 'when search for sub_rubric' do
    let(:name_part) { 'sub_rubric' }

    it { expect(result).to match_array([rubric1, sub_rubric]) }
  end

  context 'when search for deep sub_rubric' do
    let(:name_part) { 'deep' }

    it { expect(result).to match_array([rubric1, sub_rubric, deep_sub_rubric]) }

    it { expect(result.where(rubric_id: rubric1.id)).to match_array([sub_rubric]) }
  end

  context 'when dangerous param value' do
    let(:name_part) { "$('#tree').jstree(true).settings.core.data = newJsonData;" }

    it do
      expect { result.to_a }.not_to raise_error
    end
  end

  context 'when both rubric and sub_rubric include part' do
    let!(:deep_sub_rubric) { create :rubric, rubric: sub_rubric, name: 'my deep sub_rubric' }
    let(:name_part) { 'sub_rubric' }

    it { expect(result).to match_array([rubric1, sub_rubric, deep_sub_rubric]) }
  end
end
