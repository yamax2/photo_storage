# frozen_string_literal: true

RSpec.describe Photos::MainPhotoService do
  let(:service_context) { described_class.call(photo:) }

  let(:rubric) { create :rubric }
  let(:token) { create :'yandex/token' }
  let(:photo) { create :photo, storage_filename: 'test', rubric:, yandex_token: token }

  context 'when root rubric' do
    context 'and rubric without main photo' do
      it do
        expect { service_context }.to change { rubric.reload.main_photo }.from(nil).to(photo)
        expect(service_context).to be_a_success
      end
    end

    context 'and rubric with main photo' do
      let(:another_photo) { create :photo, local_filename: 'test' }
      let(:rubric) { create :rubric, main_photo: another_photo }

      it do
        expect { service_context }.not_to(change { rubric.reload.main_photo })
        expect(service_context).to be_a_success
      end
    end
  end

  context 'when sub_rubric' do
    let(:root_rubric) { create :rubric }
    let(:rubric) { create :rubric, rubric: root_rubric }

    context 'and rubric without main_photo' do
      it do
        expect { service_context }.
          to change { rubric.reload.main_photo }.from(nil).to(photo).
          and change { root_rubric.reload.main_photo }.from(nil).to(photo)

        expect(service_context).to be_a_success
      end
    end

    context 'and rubric with main_photo' do
      let(:another_photo) { create :photo, local_filename: 'test' }
      let(:rubric) { create :rubric, rubric: root_rubric, main_photo: another_photo }

      it do
        expect { service_context }.not_to(change { rubric.reload.main_photo })

        expect(root_rubric.reload.main_photo).to be_nil
        expect(service_context).to be_a_success
      end
    end

    context 'and parent rubric with main_photo' do
      let(:another_photo) { create :photo, local_filename: 'test' }

      let(:root_rubric) { create :rubric }
      let(:parent_rubric) { create :rubric, rubric: root_rubric, main_photo: another_photo }
      let(:rubric) { create :rubric, rubric: parent_rubric }

      it do
        expect { service_context }.to change { rubric.reload.main_photo }.from(nil).to(photo)

        expect(parent_rubric.reload.main_photo).to eq(another_photo)
        expect(root_rubric.reload.main_photo).to be_nil
        expect(service_context).to be_a_success
      end
    end
  end
end
