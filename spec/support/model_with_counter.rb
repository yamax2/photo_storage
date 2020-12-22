# frozen_string_literal: true

RSpec.shared_context 'model with counter' do |factory|
  describe '#inc_counter' do
    subject(:action!) { model.inc_counter }

    let(:redis) { RedisClassy.redis }

    context 'when persisted' do
      let(:model) { create factory, local_filename: 'test' }

      context 'and first view' do
        it do
          expect { action! }.
            to change { redis.get("counters:#{model.class.to_s.underscore}:#{model.id}") }.from(nil).to('1')

          expect(action!).to eq(1)
        end
      end

      context 'and second view' do
        before { model.inc_counter }

        it do
          expect { action! }.
            to change { redis.get("counters:#{model.class.to_s.underscore}:#{model.id}") }.from('1').to('2')

          expect(action!).to eq(2)
        end
      end

      context 'and counter with ttl' do
        let(:key) { "counters:#{factory}:#{model.id}" }

        before do
          redis.set(key, 0)
          redis.expire(key, 30.minutes)
        end

        it do
          expect(redis.ttl(key)).to be_positive
          expect { action! }.to change { redis.ttl(key) }.to(-1)

          expect(action!).to eq(1)
        end
      end
    end

    context 'when not persisted' do
      let(:model) { build factory }

      it do
        expect { action! }.not_to(change { RedisClassy.redis.keys('counters:*') })

        expect(action!).to be_nil
      end
    end
  end
end
