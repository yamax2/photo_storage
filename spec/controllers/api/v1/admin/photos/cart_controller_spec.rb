# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Admin::Photos::CartController do
  render_views

  let(:json) { JSON.parse(response.body) }
  let(:redis) { RedisClassy.redis }
  let(:key) { "cart:photos:#{photo.rubric_id}" }

  describe '#create' do
    context 'when wrong photo' do
      subject { post :create, params: {photo_id: 1} }

      it do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when correct photo' do
      let(:photo) { create :photo, local_filename: 'test' }

      subject { post :create, params: {photo_id: photo.id} }

      context 'and photo already in cart' do
        before { redis.sadd(key, photo.id) }

        it do
          expect(photo.rubric).not_to be_nil
          expect(redis.smembers(key)).to match_array([photo.id.to_s])
          expect { subject }.not_to(change { redis.smembers(key) })
        end
      end

      context 'and photo not in cart' do
        it do
          expect(photo.rubric).not_to be_nil
          expect { subject }.to change { redis.smembers(key) }.from([]).to([photo.id.to_s])
        end
      end
    end
  end

  describe '#destroy' do
    context 'when wrong photo' do
      subject { delete :destroy, params: {photo_id: 1} }

      it do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when correct photo' do
      let(:photo) { create :photo, local_filename: 'test' }

      subject { delete :destroy, params: {photo_id: photo.id} }

      context 'and photo in cart' do
        before { redis.sadd(key, photo.id) }

        it do
          expect(photo.rubric).not_to be_nil
          expect { subject }.to change { redis.smembers(key) }.from([photo.id.to_s]).to([])
        end
      end

      context 'and photo not in cart' do
        it do
          expect(photo.rubric).not_to be_nil
          expect(redis.smembers(key)).to be_empty
          expect { subject }.not_to(change { redis.smembers(key) })
        end
      end
    end
  end
end
