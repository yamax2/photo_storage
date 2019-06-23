require 'rails_helper'

RSpec.describe RubricDecorator do
  describe '#rubrics_tree' do
    let(:rubric1) { create :rubric }
    let(:rubric2) { create :rubric, rubric: rubric1 }
    let(:rubric3) { create :rubric, rubric: rubric2 }

    subject { rubric3.decorate }

    it do
      expect(subject.rubrics_tree).to eq([rubric3, rubric2, rubric1])
    end
  end
end
