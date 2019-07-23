require 'rails_helper'

RSpec.describe PhotoDecorator do
  subject { photo.decorate }

  before do
    allow(Rails.application.routes).to receive(:default_url_options).and_return(host: 'test.org', protocol: 'https')
    allow(Rails.application.config).to receive(:photo_sizes).and_return(
      thumb: ->(photo) { photo.width / 2 },
      preview: 900
    )
  end

  describe '#current_views' do
    before { RedisClassy.flushdb }
    after { RedisClassy.flushdb }

    let(:photo) { create :photo, :fake, views: 1_000, local_filename: 'test' }

    context 'when first call' do
      it { expect(subject.current_views).to eq(1_001) }
    end

    context 'when second call' do
      before { subject.inc_counter }

      it { expect(subject.current_views).to eq(1_002) }
    end
  end

  describe '#image_size' do
    let(:photo) { create :photo, :fake, width: 1_000, height: 2_000, local_filename: 'test' }

    it do
      expect(subject.image_size).to eq([500, 1_000])
    end
  end

  describe '#url' do
    context 'when photo is not uploaded' do
      let(:photo) { create :photo, :fake, yandex_token: nil, local_filename: 'test' }

      it { expect(subject.url).to be_nil }
    end

    context 'sizes' do
      let(:token) { create :'yandex/token', dir: '/photos' }
      let(:photo) do
        create :photo, :fake, storage_filename: '001/002/test.jpg',
                              yandex_token: token,
                              width: 200,
                              original_filename: 'test.jpg'
      end

      context 'when original size' do
        it do
          expect(subject.url).
            to eq("https://proxy.test.org/originals/photos/001/002/test.jpg?fn=test.jpg&id=#{token.id}")
        end
      end

      context 'when thumb' do
        it do
          expect(subject.url(:thumb)).
            to eq("https://proxy.test.org/photos/001/002/test.jpg?preview&size=100&id=#{token.id}")
        end
      end

      context 'when preview' do
        it do
          expect(subject.url(:preview)).
            to eq("https://proxy.test.org/photos/001/002/test.jpg?preview&size=900&id=#{token.id}")
        end
      end

      context 'when wrong size type' do
        it do
          expect { subject.url(:wrong) }.to raise_error(KeyError)
        end
      end
    end
  end
end
