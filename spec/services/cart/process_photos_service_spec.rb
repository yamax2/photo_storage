# frozen_string_literal: true

RSpec.describe Cart::ProcessPhotosService do
  let(:rubric) { create :rubric }
  let(:redis) { RedisClassy.redis }
  let(:key) { "cart:photos:#{rubric.id}" }

  context 'when call without a block' do
    it do
      expect { described_class.call(rubric.id) }.to raise_error('no block given')
    end
  end

  context 'when call for empty cart' do
    before do
      create(:photo, local_filename: 'test', rubric:)
      create :photo, local_filename: 'test', rubric:
    end

    let(:service_call) { described_class.call(rubric.id, &:save!) }

    it do
      expect { service_call }.not_to raise_error
    end
  end

  context 'when some photos in cart' do
    let!(:photo1) { create :photo, local_filename: 'test', rubric:, name: '11' }
    let!(:photo2) { create :photo, local_filename: 'test', rubric:, name: '22' }

    before do
      redis.sadd(key, photo1.id)
      redis.sadd(key, photo2.id)
      redis.sadd(key, photo1.id * 2)
      redis.sadd(key, photo2.id * 2)
    end

    context 'when try to remove from cart' do
      let(:service_call) do
        described_class.call(rubric.id) do |photo|
          photo.update!(name: 'say ni')
          true
        end
      end

      it do
        expect { service_call }.
          to change { photo1.reload.name }.from('11').to('say ni').
          and change { photo2.reload.name }.from('22').to('say ni')

        expect(redis.smembers(key)).to be_empty
      end
    end

    context 'when try not to remove from cart' do
      let(:service_call) do
        described_class.call(rubric.id) do |photo|
          photo.update!(name: 'say ni')
          false
        end
      end

      it do
        expect { service_call }.
          to change { photo1.reload.name }.from('11').to('say ni').
          and change { photo2.reload.name }.from('22').to('say ni')

        expect(redis.smembers(key)).to match_array([photo1.id.to_s, photo2.id.to_s])
      end
    end
  end
end
