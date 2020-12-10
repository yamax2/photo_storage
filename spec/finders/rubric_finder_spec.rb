# frozen_string_literal: true

RSpec.describe RubricFinder do
  subject(:result) { described_class.call(rubric_id) }

  let(:rubric_id) { 111 }

  context 'when wrong rubric' do
    it do
      expect { result }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when first level rubric' do
    let(:rubric) { create :rubric }
    let(:rubric_id) { rubric.id }

    it do
      expect(result).to eq(rubric)
      expect(result.rubric).to be_nil
    end
  end

  context 'when third level rubric' do
    let(:rubric1) { create :rubric }
    let(:rubric2) { create :rubric, rubric: rubric1 }
    let(:rubric3) { create :rubric, rubric: rubric2 }

    let(:rubric_id) { rubric3.id }

    it do
      expect(result).to eq(rubric3)

      expect(result.rubric).to eq(rubric2)
      expect(result.association(:rubric)).to be_loaded

      expect(result.rubric.rubric).to eq(rubric1)
      expect(result.rubric.association(:rubric)).to be_loaded
    end
  end
end
