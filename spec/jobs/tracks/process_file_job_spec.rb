# frozen_string_literal: true

RSpec.describe Tracks::ProcessFileJob do
  context 'when track exists' do
    let(:track) { create :track, local_filename: 'zozo' }

    it do
      expect(Tracks::Process).to receive(:call!).with(track:, storage_filename: 'test')

      expect { described_class.new.perform(track.id, 'test') }.not_to raise_error
    end
  end

  context 'when track does not exist' do
    it do
      expect(Tracks::Process).not_to receive(:call!)

      expect { described_class.new.perform(2, 'test') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
