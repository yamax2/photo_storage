# frozen_string_literal: true

RSpec.describe Rubrics::ApplyMainPhotoService do
  let(:service_context) { described_class.call(photo: photo, rubric: rubric) }

  context 'when wrong rubric' do
    let(:rubric) { create :rubric }
    let(:photo) { create :photo, local_filename: 'test' }

    it do
      expect(photo.rubric).not_to eq(rubric)
      expect(service_context).to be_a_failure
      expect(service_context.message).to eq("#{photo.id} does not belong to rubric #{rubric.id}")
    end
  end

  context 'when rubric without parent' do
    let(:rubric) { create :rubric }
    let(:photo) { create :photo, local_filename: 'test', rubric: rubric }

    it do
      expect { service_context }.to change { rubric.reload.main_photo }.from(nil).to(photo)

      expect(service_context).to be_a_success
    end
  end

  context 'when rubric with parents' do
    let(:some_photo) { create :photo, local_filename: 'test', rubric: rubric2 }
    let(:photo) { create :photo, local_filename: 'test', rubric: rubric }

    let(:rubric1) { create :rubric }
    let(:rubric2) { create :rubric, rubric: rubric1 }
    let(:rubric) { create :rubric, rubric: rubric2 }

    before do
      rubric2.update!(main_photo: some_photo)
    end

    it do
      expect { service_context }.
        to change { rubric1.reload.main_photo }.from(nil).to(photo).
        and change { rubric.reload.main_photo }.from(nil).to(photo)

      expect(service_context).to be_a_success
      expect(rubric2.reload.main_photo).to eq(some_photo)
    end
  end
end
