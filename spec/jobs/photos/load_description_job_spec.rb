require 'rails_helper'

RSpec.describe Photos::LoadDescriptionJob do
  let(:photo) { create :photo, :fake, local_filename: 'test' }

  before do
    allow(Photos::LoadDescriptionService).to receive(:call!)
    described_class.perform_async(photo.id)
  end

  it do
    expect(Photos::LoadDescriptionService).to have_received(:call!).with(photo: photo)
  end
end