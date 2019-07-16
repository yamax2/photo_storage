require 'rails_helper'

RSpec.describe Rubrics::ApplyOrder do
  context 'when root rubric' do
    let(:service_context) do
      described_class.call(data: [rubric4.id, rubric3.id, rubric2.id, rubric1.id, rubric4.id * 2])
    end

    let!(:rubric1) { create :rubric }
    let!(:rubric2) { create :rubric, ord: 2 }
    let!(:rubric3) { create :rubric, ord: 10 }
    let!(:rubric4) { create :rubric }

    context 'and correct parent' do
      it do
        expect(service_context).to be_a_success

        expect(rubric4.reload.ord).to eq(0)
        expect(rubric3.reload.ord).to eq(1)
        expect(rubric2.reload.ord).to eq(2)
        expect(rubric1.reload.ord).to eq(3)
      end
    end

    context 'and one rubric is incorrect' do
      let(:parent_rubric) { create :rubric }
      let!(:rubric1) { create :rubric, rubric: parent_rubric }

      it do
        expect(service_context).to be_a_failure
        expect(service_context.message).to eq("wrong parent rubric for #{rubric1.id}, expected ")

        expect(rubric4.reload.ord).to be_nil
        expect(rubric3.reload.ord).to eq(10)
        expect(rubric2.reload.ord).to eq(2)
        expect(rubric1.reload.ord).to be_nil
      end
    end
  end

  context 'when sub rubric' do
    let(:parent_rubric) { create :rubric }

    let(:service_context) do
      described_class.call(
        data: [rubric4.id, rubric3.id, rubric2.id, rubric1.id, rubric4.id * 2],
        id: parent_rubric.id
      )
    end

    let!(:rubric1) { create :rubric, rubric: parent_rubric }
    let!(:rubric2) { create :rubric, ord: 2, rubric: parent_rubric }
    let!(:rubric3) { create :rubric, ord: 10, rubric: parent_rubric }
    let!(:rubric4) { create :rubric, rubric: parent_rubric }

    context 'and correct parent' do
      it do
        expect(service_context).to be_a_success

        expect(rubric4.reload.ord).to eq(0)
        expect(rubric3.reload.ord).to eq(1)
        expect(rubric2.reload.ord).to eq(2)
        expect(rubric1.reload.ord).to eq(3)
      end
    end

    context 'and one rubric is incorrect' do
      let!(:rubric1) { create :rubric }

      it do
        expect(service_context).to be_a_failure
        expect(service_context.message).to eq("wrong parent rubric for #{rubric1.id}, expected #{parent_rubric.id}")

        expect(rubric4.reload.ord).to be_nil
        expect(rubric3.reload.ord).to eq(10)
        expect(rubric2.reload.ord).to eq(2)
        expect(rubric1.reload.ord).to be_nil
      end
    end
  end
end