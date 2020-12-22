# frozen_string_literal: true

RSpec.describe Counters::DumpService do
  subject(:dump!) { described_class.call!(model_klass: Photo) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  let(:redis) { RedisClassy.redis }
  let!(:photo_without_views) { create :photo, local_filename: 'test', views: 0 }
  let!(:photo_with_views) { create :photo, local_filename: 'test', views: 1_000 }
  let!(:wrong_photo) { create :photo, local_filename: 'test', views: 2_000 }

  context 'when no counters in redis' do
    it do
      expect { dump! }.
        to change { photo_without_views.reload.views }.by(0).
        and change { photo_with_views.reload.views }.by(0).
        and change { wrong_photo.reload.views }.by(0)
    end
  end

  context 'when information presents' do
    before do
      redis.set("counters:photo:#{photo_with_views.id * 2}", 1_000)
      redis.set("counters:photo:#{photo_without_views.id}", 100)
      redis.set("counters:photo:#{photo_with_views.id}", 10)
    end

    context 'when regular call' do
      it do
        expect { dump! }.
          to change { photo_without_views.reload.views }.by(100).
          and change { photo_with_views.reload.views }.by(10).
          and change { wrong_photo.reload.views }.by(0)

        expect(redis.keys).to match_array(
          [
            "counters:photo:#{photo_with_views.id * 2}",
            "counters:photo:#{photo_without_views.id}",
            "counters:photo:#{photo_with_views.id}"
          ]
        )

        expect(redis.ttl("counters:photo:#{photo_with_views.id * 2}")).to be_positive

        expect(redis.get("counters:photo:#{photo_without_views.id}")).to eq('0')
        expect(redis.ttl("counters:photo:#{photo_without_views.id}")).to be_positive

        expect(redis.get("counters:photo:#{photo_with_views.id}")).to eq('0')
        expect(redis.ttl("counters:photo:#{photo_with_views.id}")).to be_positive
      end
    end
  end
end
