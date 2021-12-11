# frozen_string_literal: true

RSpec.describe Videos::StoreService do
  let(:video) { build :photo, :video, original_filename: 'test.mp4' }
  let!(:node) { create :'yandex/token', active: true }
  let(:hex) { '84be4315c54a8cafa09a74a45d60936ff7c2df14' }

  before do
    allow(SecureRandom).to receive(:hex).and_call_original
    allow(SecureRandom).to receive(:hex).with(20).and_return(hex)

    described_class.new(video).call
  end

  it do
    expect(video).to be_valid
    expect(video).to have_attributes(
      yandex_token: node,
      storage_filename: "video#{hex}.mp4",
      preview_filename: "#{video.storage_filename}.jpg"
    )
  end
end
