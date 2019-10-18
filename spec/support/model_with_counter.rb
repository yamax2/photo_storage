# frozen_string_literal: true

RSpec.shared_context 'model with counter' do |factory|
  describe '#inc_counter' do
    before { RedisClassy.flushdb }
    after { RedisClassy.flushdb }

    let(:redis) { RedisClassy.redis }

    subject { model.inc_counter }

    context 'when persisted' do
      let(:model) { create :photo, :fake, local_filename: 'test' }

      context 'and first view' do
        it do
          expect { subject }.
            to change { redis.get("counters:#{model.class.to_s.underscore}:#{model.id}") }.from(nil).to('1')

          is_expected.to eq(1)
        end
      end

      context 'and second view' do
        before { model.inc_counter }

        it do
          expect { subject }.
            to change { redis.get("counters:#{model.class.to_s.underscore}:#{model.id}") }.from('1').to('2')

          is_expected.to eq(2)
        end
      end

      context 'and counter with ttl' do
        let(:key) { "counters:photo:#{model.id}" }

        before do
          redis.set(key, 0)
          redis.expire(key, 30.minutes)
        end

        it do
          expect(redis.ttl(key)).to be_positive
          expect { subject }.to change { redis.ttl(key) }.to(-1)

          is_expected.to eq(1)
        end
      end
    end

    context 'when not persisted' do
      let(:model) { build factory }

      it do
        expect { subject }.not_to(change { RedisClassy.redis.keys('counters:*') })

        is_expected.to be_nil
      end
    end
  end
end
