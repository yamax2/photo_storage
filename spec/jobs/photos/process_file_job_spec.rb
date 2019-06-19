require 'rails_helper'

RSpec.describe Photos::ProcessFileJob do
  before do
    allow(Photos::Process).to receive(:call!)
  end

  subject { described_class.perform_async(photo_id) }

  context 'when photo exists' do
    let(:photo) { create :photo, :fake, local_filename: 'zozo' }
    let(:photo_id) { photo.id }

    before { subject }

    it do
      expect(Photos::Process).to have_received(:call!).with(photo: photo)
    end
  end

  context 'when photo does not exist' do
    let(:photo_id) { 2 }

    it do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
