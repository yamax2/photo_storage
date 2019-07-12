require 'rails_helper'

RSpec.describe Counters::DumpService do
  before { RedisClassy.flushdb }
  after { RedisClassy.flushdb }

  let(:redis) { RedisClassy.redis }

  subject { described_class.call!(model_klass: Photo) }

  let!(:photo_without_views) { create :photo, :fake, local_filename: 'test', views: 0 }
  let!(:photo_with_views) { create :photo, :fake, local_filename: 'test', views: 1_000 }
  let!(:wrong_photo) { create :photo, :fake, local_filename: 'test', views: 2_000 }

  context 'when no counters in redis' do
    it do
      expect { subject }.
        to change { photo_without_views.reload.views }.by(0).
        and change { photo_with_views.reload.views }.by(0).
        and change { wrong_photo.reload.views }.by(0)
    end
  end

  context 'when information presents' do
    before do
      redis.set("counters:photo:#{photo_without_views.id}", 100)
      redis.set("counters:photo:#{photo_with_views.id}", 10)
      redis.set("counters:photo:#{photo_with_views.id * 2}", 1_000)
    end

    context 'when regular call' do
      it do
        expect { subject }.
          to change { photo_without_views.reload.views }.by(100).
          and change { photo_with_views.reload.views }.by(10).
          and change { wrong_photo.reload.views }.by(0)

        expect(redis.keys).to be_empty
      end
    end
  end
end
