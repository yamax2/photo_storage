# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhotoDecorator do
  subject { photo.decorate }

  before do
    allow(Rails.application.routes).to receive(:default_url_options).and_return(host: 'test.org', protocol: 'https')

    allow(Rails.application.config).to receive(:photo_sizes).and_return(
      thumb: ->(photo) { photo.width * 360 / photo.height },
      preview: 900
    )

    allow(Rails.application.config).to receive(:max_thumb_width).and_return(1_280)
  end

  describe '#current_views' do
    before { RedisClassy.flushdb }
    after { RedisClassy.flushdb }

    let(:photo) { create :photo, views: 1_000, local_filename: 'test' }

    context 'when first call' do
      it { expect(subject.current_views).to eq(1_001) }
    end

    context 'when second call' do
      before { subject.inc_counter }

      it { expect(subject.current_views).to eq(1_002) }
    end
  end

  describe '#image_size' do
    context 'when simple photo' do
      let(:photo) { create :photo, width: 1_000, height: 2_000, local_filename: 'test' }

      it do
        expect(subject.image_size).to eq([180, 360])
        expect(subject.image_size(:preview)).to eq([900, 1_800])
      end
    end

    context 'when wide photo' do
      let(:photo) { create :photo, width: 3_000, height: 300, local_filename: 'test' }

      it do
        expect(subject.image_size).to eq([1_280, 360])
        expect(subject.image_size(:preview)).to eq([900, 90])
      end
    end
  end

  describe '#url' do
    context 'when photo is not uploaded' do
      let(:photo) { create :photo, yandex_token: nil, local_filename: 'test' }

      it { expect(subject.url).to be_nil }
    end

    context 'sizes' do
      let(:token) { create :'yandex/token', dir: '/photos' }
      let(:photo) do
        create :photo, storage_filename: '001/002/test.jpg',
                       yandex_token: token,
                       width: 200,
                       height: 400,
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
            to eq("https://proxy.test.org/photos/001/002/test.jpg?preview&size=180&id=#{token.id}")
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
