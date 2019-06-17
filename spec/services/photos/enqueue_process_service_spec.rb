require 'rails_helper'

RSpec.describe Photos::EnqueueProcessService do
  let(:rubric) { create :rubric }
  let(:service_context) { described_class.call(uploaded_io: image, rubric_id: rubric.id) }
  let(:photo) { service_context.photo }

  before { allow(SecureRandom).to receive(:hex).and_return('test.jpg') }
  after { FileUtils.rm_f(photo.tmp_local_filename) }

  context 'when correct file' do
    let(:image) { fixture_file_upload('spec/fixtures/test2.jpg', 'image/jpeg') }

    it do
      expect { service_context }.to change { Photo.count }.by(1)

      expect(File.exist?(photo.tmp_local_filename)).to eq(true)
      expect(service_context).to be_a_success

      expect(photo).to be_valid
      expect(photo).to be_persisted
      expect(photo).to have_attributes(
        size: 2_236_570,
        content_type: 'image/jpeg',
        original_filename: 'test2.jpg',
        name: 'test2.jpg',
        rubric_id: rubric.id,
        local_filename: 'test.jpg'
      )
    end
  end

  context 'when wrong file' do
    let(:image) { fixture_file_upload('spec/fixtures/test.txt', 'text/plain') }

    it do
      expect(service_context).to be_a_failure
      expect(File.exist?(photo.tmp_local_filename)).to eq(true)

      expect(photo).not_to be_valid
      expect(photo).not_to be_persisted
    end
  end
end
