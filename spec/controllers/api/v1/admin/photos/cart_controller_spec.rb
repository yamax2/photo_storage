# frozen_string_literal: true

RSpec.describe Api::V1::Admin::Photos::CartController, type: :request do
  let(:redis) { RedisClassy.redis }
  let(:key) { "cart:photos:#{photo.rubric_id}" }

  describe '#create' do
    context 'when wrong photo' do
      subject(:request) { post api_v1_admin_photos_cart_url(photo_id: 1) }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when correct photo' do
      subject(:request) { post api_v1_admin_photos_cart_url(photo_id: photo.id) }

      let(:photo) { create :photo, local_filename: 'test' }

      context 'and photo already in cart' do
        before { redis.sadd(key, photo.id) }

        it do
          expect(photo.rubric).not_to be_nil
          expect(redis.smembers(key)).to match_array([photo.id.to_s])
          expect { request }.not_to(change { redis.smembers(key) })
        end
      end

      context 'and photo not in cart' do
        it do
          expect(photo.rubric).not_to be_nil
          expect { request }.to change { redis.smembers(key) }.from([]).to([photo.id.to_s])
        end
      end
    end

    context 'when with auth' do
      let(:photo) { create :photo, local_filename: 'test' }
      let(:request_proc) { ->(headers) { post api_v1_admin_photos_cart_url(photo_id: photo.id), headers: } }

      it_behaves_like 'admin restricted route', api: true
    end
  end

  describe '#destroy' do
    context 'when wrong photo' do
      subject(:request) { delete api_v1_admin_photos_cart_url(photo_id: 1) }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when correct photo' do
      subject(:request) { delete api_v1_admin_photos_cart_url(photo_id: photo.id) }

      let(:photo) { create :photo, local_filename: 'test' }

      context 'and photo in cart' do
        before { redis.sadd(key, photo.id) }

        it do
          expect(photo.rubric).not_to be_nil
          expect { request }.to change { redis.smembers(key) }.from([photo.id.to_s]).to([])
        end
      end

      context 'and photo not in cart' do
        it do
          expect(photo.rubric).not_to be_nil
          expect(redis.smembers(key)).to be_empty
          expect { request }.not_to(change { redis.smembers(key) })
        end
      end
    end

    context 'when with auth' do
      let(:photo) { create :photo, local_filename: 'test' }
      let(:request_proc) { ->(headers) { delete api_v1_admin_photos_cart_url(photo_id: photo.id), headers: } }

      it_behaves_like 'admin restricted route', api: true
    end
  end
end
