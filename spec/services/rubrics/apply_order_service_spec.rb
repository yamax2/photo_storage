require 'rails_helper'

RSpec.describe Rubrics::ApplyOrderService do
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

        expect(rubric4.reload.ord).to eq(1)
        expect(rubric3.reload.ord).to eq(2)
        expect(rubric2.reload.ord).to eq(3)
        expect(rubric1.reload.ord).to eq(4)
      end
    end

    context 'and one rubric is incorrect' do
      let(:parent_rubric) { create :rubric }
      let!(:rubric4) { create :rubric, rubric: parent_rubric }

      it do
        expect(service_context).to be_a_success

        expect(rubric4.reload.ord).to be_nil
        expect(rubric3.reload.ord).to eq(1)
        expect(rubric2.reload.ord).to eq(2)
        expect(rubric1.reload.ord).to eq(3)
      end
    end
  end

  context 'when large amount of rubrics' do
    let!(:rubrics) { create_list :rubric, 1_000 }

    it do
      expect { described_class.call!(data: Rubric.pluck(:id).shuffle) }.
        to change { Rubric.where(ord: nil).count }.from(1_000).to(0)
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

        expect(rubric4.reload.ord).to eq(1)
        expect(rubric3.reload.ord).to eq(2)
        expect(rubric2.reload.ord).to eq(3)
        expect(rubric1.reload.ord).to eq(4)
      end
    end

    context 'and one rubric is incorrect' do
      let!(:rubric1) { create :rubric }

      it do
        expect(service_context).to be_a_success

        expect(rubric1.reload.ord).to be_nil
        expect(rubric4.reload.ord).to eq(1)
        expect(rubric3.reload.ord).to eq(2)
        expect(rubric2.reload.ord).to eq(3)
      end
    end
  end

  describe 'errors' do
    let!(:rubric) { create :rubric }

    context 'when wrong id param' do
      context 'and id is 0' do
        it do
          expect { described_class.call(data: [rubric.id, rubric.id], id: 0) }.
            to change { rubric.reload.ord }.from(nil).to(1)
        end
      end

      context 'and id is negative' do
        it do
          expect { described_class.call(data: [rubric.id, rubric.id], id: -1) }.
            to change { rubric.reload.ord }.from(nil).to(1)
        end
      end

      context 'and id is non-existing' do
        it do
          expect { described_class.call(data: [rubric.id, rubric.id], id: rubric.id * 2) }.
            not_to(change { rubric.reload.ord })
        end
      end

      context 'and id is a string' do
        it do
          expect { described_class.call(data: [rubric.id, rubric.id], id: rubric.id.to_s) }.
            not_to(change { rubric.reload.ord })
        end
      end
    end

    context 'when duplicates in data' do
      it do
        expect { described_class.call(data: [rubric.id, rubric.id]) }.
          to change { rubric.reload.ord }.from(nil).to(1)
      end
    end
  end
end
