# frozen_string_literal: true

RSpec.describe ProxyUrls::Track do
  subject(:url) { described_class.new(track).generate }

  context 'when track is not uploaded' do
    let(:track) { create :track, local_filename: 'test' }

    it { is_expected.to be_nil }
  end

  context 'when track is uploaded' do
    let(:token) { create :'yandex/token', other_dir: '/other' }
    let(:track) { create :track, storage_filename: 'test.gpx', yandex_token: token, original_filename: 'my.gpx' }

    it { is_expected.to eq("/proxy/yandex/other/test.gpx?fn=my.gpx&id=#{token.id}") }
  end

  context 'when folder_index is greater than zero' do
    let(:token) { create :'yandex/token', other_dir: '/other' }
    let(:track) do
      create :track, storage_filename: 'test.gpx', yandex_token: token, original_filename: 'my.gpx', folder_index: 3
    end

    it { is_expected.to eq("/proxy/yandex/other3/test.gpx?fn=my.gpx&id=#{token.id}") }
  end
end
