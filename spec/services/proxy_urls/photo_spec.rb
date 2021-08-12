# frozen_string_literal: true

RSpec.describe ProxyUrls::Photo do
  subject(:generator) { described_class.new(photo) }

  context 'when photo is not uploaded' do
    let(:photo) { create :photo, yandex_token: nil, local_filename: 'test' }

    it { expect(generator.generate).to be_nil }
  end

  context 'when photo is uploaded' do
    let(:token) { create :'yandex/token', dir: '/photos' }
    let(:photo) do
      create :photo,
             storage_filename: '001/002/test.jpg',
             yandex_token: token,
             width: 5_152,
             height: 3_864,
             original_filename: 'test.jpg'
    end

    context 'when original size' do
      it do
        expect(generator.generate).
          to eq("/proxy/yandex/photos/001/002/test.jpg?fn=test.jpg&id=#{token.id}")
      end
    end

    context 'when small thumb' do
      it do
        expect(generator.generate(:thumb, [480, 640])).
          to eq("/proxy/yandex/previews/photos/001/002/test.jpg?id=#{token.id}&size=480")
      end
    end

    context 'when large preview' do
      it do
        expect(generator.generate(:p2k, [3_000, 2_000])).
          to eq("/proxy/yandex/resize/photos/001/002/test.jpg?id=#{token.id}&size=3000")
      end
    end
  end
end
