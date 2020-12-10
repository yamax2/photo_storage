# frozen_string_literal: true

RSpec.describe Cart::PhotoService do
  let(:service_context) { described_class.call!(photo: photo, remove: remove) }
  let(:redis) { RedisClassy.redis }
  let(:rubric) { create :rubric }
  let(:cart_key) { "cart:photos:#{rubric.id}" }

  context 'when photo is not persisted' do
    let(:photo) { build :photo, local_filename: 'test', rubric: rubric }
    let(:remove) { false }

    it do
      expect(photo.rubric_id).not_to be_nil

      expect { service_context }.not_to(change { redis.smembers(cart_key) })
    end
  end

  context 'when add correct photo' do
    let(:remove) { false }
    let(:photo) { create :photo, local_filename: 'test', rubric: rubric }

    context 'and photo already in cart' do
      before { redis.sadd(cart_key, photo.id) }

      it do
        expect(redis.smembers(cart_key).map(&:to_i)).to match_array([photo.id])

        expect { service_context }.not_to(change { redis.smembers(cart_key) })
      end
    end

    context 'and photo not in cart' do
      it do
        expect { service_context }.to change { redis.smembers(cart_key).map(&:to_i) }.from([]).to([photo.id])
      end
    end
  end

  context 'when remove correct photo' do
    let(:remove) { true }
    let(:photo) { create :photo, local_filename: 'test', rubric: rubric }

    context 'and photo not in cart' do
      it do
        expect { service_context }.not_to(change { redis.smembers(cart_key) })
      end
    end

    context 'and photo in cart' do
      before { redis.sadd(cart_key, photo.id) }

      it do
        expect { service_context }.to change { redis.smembers(cart_key).map(&:to_i) }.from([photo.id]).to([])
      end
    end
  end
end
