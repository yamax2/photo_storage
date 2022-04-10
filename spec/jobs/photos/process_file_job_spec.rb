# frozen_string_literal: true

RSpec.describe Photos::ProcessFileJob do
  context 'when photo exists' do
    let(:photo) { create :photo, local_filename: 'zozo' }

    it do
      expect(Photos::Process).to receive(:call!).with(photo:, storage_filename: 'test')

      expect { described_class.new.perform(photo.id, 'test') }.not_to raise_error
    end
  end

  context 'when photo does not exist' do
    it do
      expect(Photos::Process).not_to receive(:call!)

      expect { described_class.new.perform(2, 'test') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
