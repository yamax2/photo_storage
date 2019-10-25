# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rubrics::ParentsFinder do
  subject { described_class.call(rubric_id) }

  context 'when rubric without parent' do
    let(:rubric) { create :rubric }
    let(:rubric_id) { rubric.id }

    it do
      is_expected.to match_array([rubric])
    end
  end

  context 'when rubric with a parent' do
    let(:rubric1) { create :rubric }
    let(:rubric2) { create :rubric, rubric: rubric1 }
    let(:rubric3) { create :rubric, rubric: rubric2 }
    let!(:wrong_rubric) { create :rubric, rubric: rubric1 }

    let(:rubric_id) { rubric3.id }

    it do
      expect(subject).to eq([rubric3, rubric2, rubric1])
    end
  end

  context 'when non-existent rubric' do
    let(:rubric_id) { 100_500 }

    it { is_expected.to be_empty }
  end
end
