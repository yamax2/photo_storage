# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tracks::ProcessFileJob do
  context 'when track exists' do
    let(:track) { create :track, local_filename: 'zozo' }

    it do
      expect(Tracks::Process).to receive(:call!).with(track: track)

      expect { described_class.perform_async(track.id) }.not_to raise_error
    end
  end

  context 'when track does not exist' do
    it do
      expect(Tracks::Process).not_to receive(:call!)

      expect { described_class.perform_async(2) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
