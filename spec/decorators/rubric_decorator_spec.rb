# frozen_string_literal: true

RSpec.describe RubricDecorator do
  describe '#rubrics_tree' do
    subject(:decorated_rubric) { rubric3.decorate }

    let(:rubric1) { create :rubric }
    let(:rubric2) { create :rubric, rubric: rubric1 }
    let(:rubric3) { create :rubric, rubric: rubric2 }

    it { expect(decorated_rubric.rubrics_tree).to eq([rubric3, rubric2, rubric1]) }
  end
end
