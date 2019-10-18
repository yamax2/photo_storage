# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RubricFinder do
  let(:rubric_id) { 111 }

  subject { described_class.call(rubric_id) }

  context 'when wrong rubric' do
    it do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when first level rubric' do
    let(:rubric) { create :rubric }
    let(:rubric_id) { rubric.id }

    it do
      is_expected.to eq(rubric)
      expect(subject.rubric).to be_nil
    end
  end

  context 'when third level rubric' do
    let(:rubric1) { create :rubric }
    let(:rubric2) { create :rubric, rubric: rubric1 }
    let(:rubric3) { create :rubric, rubric: rubric2 }

    let(:rubric_id) { rubric3.id }

    it do
      is_expected.to eq(rubric3)

      expect(subject.rubric).to eq(rubric2)
      expect(subject.association(:rubric)).to be_loaded

      expect(subject.rubric.rubric).to eq(rubric1)
      expect(subject.rubric.association(:rubric)).to be_loaded
    end
  end
end
