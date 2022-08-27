# frozen_string_literal: true

RSpec.describe Videos::StoreService do
  let(:video) do
    build :photo,
          :video,
          original_filename: 'test.mp4',
          preview_filename: nil,
          video_preview_filename: nil
  end

  let!(:node) { create :'yandex/token', active: true, other_folder_index: 2 }
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
      folder_index: 2,
      storage_filename: "video#{hex}.mp4",
      preview_filename: "#{video.storage_filename}.jpg",
      video_preview_filename: 'video84be4315c54a8cafa09a74a45d60936ff7c2df14.preview.mp4'
    )
  end
end
