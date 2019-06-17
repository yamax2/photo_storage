require 'rails_helper'

RSpec.describe Photos::UploadService do
  let(:service_context) { described_class.call(photo: photo) }

  context 'when file already uploaded' do
    let(:photo) { create :photo, storage_filename: 'test.jpg' }

    it { expect(service_context).to be_a_success }
  end

  context 'when active token does not exist' do
    let(:photo) { create :photo }

    it do
      expect(service_context).to be_a_failure
      expect(service_context.message).to eq('active token not found')
    end
  end

  context 'when correct upload' do
    context 'and to a new folder' do

    end

    context 'and to an existing folder' do

    end
  end

  context 'when upload fails' do

  end

  context 'when folder creation fails' do

  end
end
