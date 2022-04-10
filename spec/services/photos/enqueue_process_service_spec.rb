# frozen_string_literal: true

RSpec.describe Photos::EnqueueProcessService do
  let(:rubric) { create :rubric }
  let(:photo) { build :photo, :real, name: 'test', rubric: rubric }

  let(:service_context) { described_class.call(model: photo, uploaded_io: image) }

  before do
    allow(SecureRandom).to receive(:hex).and_return('test')
    allow(Photos::ProcessFileJob).to receive(:perform_async)
  end

  after { FileUtils.rm_f(photo.tmp_local_filename) }

  context 'when correct file' do
    let(:image) { fixture_file_upload('spec/fixtures/test2.jpg', 'image/jpeg') }
    let(:correct_attributes) do
      {
        size: 2_236_570,
        content_type: 'image/jpeg',
        original_filename: 'test2.jpg',
        name: 'test',
        rubric_id: rubric.id,
        local_filename: 'test'
      }
    end

    it do
      expect { service_context }.to change(photo, :persisted?).from(false).to(true)

      expect(File.exist?(photo.tmp_local_filename)).to be(true)
      expect(service_context).to be_a_success

      expect(photo).to be_valid
      expect(photo).to be_persisted

      expect(photo).to have_attributes(correct_attributes)

      expect(Photos::ProcessFileJob).to have_received(:perform_async).with(photo.id, /test\.jpg/)
    end
  end

  context 'when wrong file' do
    let(:image) { fixture_file_upload('spec/fixtures/test.txt', 'text/plain') }

    it do
      expect(service_context).to be_a_failure
      expect(File.exist?(photo.tmp_local_filename)).to be(true)

      expect(photo).not_to be_valid
      expect(photo).not_to be_persisted

      expect(Photos::ProcessFileJob).not_to have_received(:perform_async)
    end
  end
end
