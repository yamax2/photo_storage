# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Photos::EnqueueLoadDescriptionService do
  before do
    allow(Photos::LoadDescriptionJob).to receive(:perform_async)
  end

  let(:service_context) { described_class.call!(photo: photo) }

  context 'when photo without description' do
    context 'and has lat_long' do
      let(:photo) { create :photo, :fake, lat_long: [1, 2], local_filename: 'test' }

      it do
        expect(service_context).to be_a_success
        expect(Photos::LoadDescriptionJob).to have_received(:perform_async).with(photo.id)
      end
    end

    context 'and without lat_long' do
      let(:photo) { create :photo, :fake, local_filename: 'test' }

      it do
        expect(service_context).to be_a_success
        expect(Photos::LoadDescriptionJob).not_to have_received(:perform_async)
      end
    end
  end

  context 'when photo with description' do
    let(:photo) { create :photo, :fake, local_filename: 'test', lat_long: [1, 2], description: 'zozo' }

    it do
      expect(service_context).to be_a_success
      expect(Photos::LoadDescriptionJob).not_to have_received(:perform_async)
    end
  end
end
