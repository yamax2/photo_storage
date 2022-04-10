# frozen_string_literal: true

RSpec.describe PhotoDecorator do
  subject(:decorated_photo) { photo.decorate }

  before do
    allow(Rails.application.config).to receive(:photo_sizes).and_return(
      thumb: ->(photo) { photo.width * 360 / photo.height },
      preview: 900
    )

    allow(Rails.application.config).to receive(:max_thumb_width).and_return(1_280)
  end

  describe '#proxy_url' do
    context 'when photo is not uploaded' do
      let(:photo) { create :photo, yandex_token: nil, local_filename: 'test' }

      it { expect(decorated_photo.proxy_url).to be_nil }
    end

    context 'sizes' do
      let(:token) { create :'yandex/token', dir: '/photos' }
      let(:rotated) { nil }
      let(:photo) do
        create :photo,
               storage_filename: '001/002/test.jpg',
               yandex_token: token,
               width: 5_152,
               height: 3_864,
               original_filename: 'test.jpg',
               rotated:
      end

      context 'when original size' do
        it do
          expect(decorated_photo.proxy_url).
            to eq("/proxy/yandex/photos/001/002/test.jpg?fn=test.jpg&id=#{token.id}")
        end
      end

      context 'when video preview' do
        let(:photo) { create :photo, :video, storage_filename: 'test.mp4', yandex_token: token }

        it do
          expect(decorated_photo.proxy_url(:video_preview)).
            to eq("/proxy/yandex/other_test_photos/test.preview.mp4?id=#{token.id}")
        end
      end

      context 'when thumb' do
        it do
          expect(decorated_photo.proxy_url(:thumb)).
            to eq("/proxy/yandex/previews/photos/001/002/test.jpg?id=#{token.id}&size=480")
        end
      end

      context 'when preview' do
        it do
          expect(decorated_photo.proxy_url(:preview)).
            to eq("/proxy/yandex/previews/photos/001/002/test.jpg?id=#{token.id}&size=900")
        end
      end

      context 'when thumb and rotated 90 deg' do
        let(:rotated) { 1 }

        it do
          expect(decorated_photo.proxy_url(:thumb)).
            to eq("/proxy/yandex/previews/photos/001/002/test.jpg?id=#{token.id}&size=360")
        end
      end

      context 'when thumb and rotated 180 deg' do
        let(:rotated) { 2 }

        it do
          expect(decorated_photo.proxy_url(:thumb)).
            to eq("/proxy/yandex/previews/photos/001/002/test.jpg?id=#{token.id}&size=480")
        end
      end

      context 'when wrong size type' do
        it do
          expect { decorated_photo.proxy_url(:wrong) }.to raise_error(KeyError)
        end
      end
    end
  end

  describe '#image_size' do
    let(:photo) { create :photo, yandex_token: nil, local_filename: 'test', width: 500, height: 400 }

    it { expect(decorated_photo.image_size).to eq([450, 360]) }
  end

  describe '#css_transform' do
    let(:photo) { create :photo, yandex_token: nil, local_filename: 'test', rotated: 1 }

    it { expect(decorated_photo.css_transform).to eq('rotate(90deg)') }
  end

  describe '#turned?' do
    let(:photo) { create :photo, yandex_token: nil, local_filename: 'test', rotated: 1 }

    it { expect(decorated_photo.turned?).to be(true) }
  end
end
