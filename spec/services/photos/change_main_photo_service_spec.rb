# frozen_string_literal: true

RSpec.describe Photos::ChangeMainPhotoService do
  subject(:change!) do
    Photo.where(id: photo.id).update_all(rubric_id: new_rubric.id)
    photo.reload

    described_class.call!(photo:)
  end

  let(:old_rubric) { create :rubric }
  let(:new_rubric) { create :rubric }

  let!(:another_photo) { create :photo, local_filename: 'test', rubric: old_rubric }
  let(:photo) { create :photo, local_filename: 'test', rubric: old_rubric }

  before do
    old_rubric
    new_rubric
  end

  context 'when simple change to a new rubric' do
    before do
      Rubric.where(id: old_rubric.id).update_all(main_photo_id: photo.id)
    end

    it do
      expect { change! }.to change { old_rubric.reload.main_photo }.from(photo).to(another_photo)
    end
  end

  context 'when photo from sub rubric changes' do
    let(:root_rubric) { create :rubric }
    let(:old_rubric) { create :rubric, rubric: root_rubric }

    before do
      Rubric.where(id: [root_rubric.id, old_rubric.id]).update_all(main_photo_id: photo.id)
    end

    it do
      expect { change! }.
        to change { old_rubric.reload.main_photo }.from(photo).to(another_photo).
        and change { root_rubric.reload.main_photo }.from(photo).to(another_photo)
    end
  end

  context 'when new rubric also belongs to the same root' do
    let(:root_rubric) { create :rubric }
    let(:old_rubric) { create :rubric, rubric: root_rubric }
    let(:new_rubric) { create :rubric, rubric: root_rubric }

    before do
      Rubric.where(id: [root_rubric.id, old_rubric.id]).update_all(main_photo_id: photo.id)
    end

    it do
      expect { change! }.to change { old_rubric.reload.main_photo }.from(photo).to(another_photo)

      expect(root_rubric.reload.main_photo).to eq(photo)
    end
  end

  context 'when move from child to parent with same main photo' do
    let(:old_rubric) { create :rubric, rubric: new_rubric }

    before do
      Rubric.where(id: [new_rubric.id, old_rubric.id]).update_all(main_photo_id: photo.id)
    end

    it do
      expect { change! }.to change { old_rubric.reload.main_photo }.from(photo).to(another_photo)

      expect(new_rubric.reload.main_photo).to eq(photo)
    end
  end
end
