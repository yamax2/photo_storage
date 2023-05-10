# frozen_string_literal: true

RSpec.shared_context 'model with counter' do |factory|
  describe '#inc_counter' do
    subject(:action!) { model.inc_counter }

    let(:redis) { Rails.application.redis }

    context 'when persisted' do
      let(:token) { create :'yandex/token' }
      let(:model) { create factory, storage_filename: 'test', yandex_token: token }

      context 'and first view' do
        it do
          expect { action! }.
            to change { redis.call('GET', "counters:#{model.class.to_s.underscore}:#{model.id}") }.from(nil).to('1')

          expect(action!).to eq(1)
        end
      end

      context 'and second view' do
        before { model.inc_counter }

        it do
          expect { action! }.
            to change { redis.call('GET', "counters:#{model.class.to_s.underscore}:#{model.id}") }.from('1').to('2')

          expect(action!).to eq(2)
        end
      end

      context 'and counter with ttl' do
        let(:key) { "counters:#{factory}:#{model.id}" }

        before do
          redis.call('SET', key, 0)
          redis.call('EXPIRE', key, 30.minutes.to_i)
        end

        it do
          expect(redis.call('TTL', key)).to be_positive
          expect { action! }.to change { redis.call('TTL', key) }.to(-1)

          expect(action!).to eq(1)
        end
      end
    end

    context 'when not persisted' do
      let(:model) { build factory }

      it do
        expect { action! }.not_to(change { redis.call('KEYS', 'counters:*') })

        expect(action!).to be_nil
      end
    end
  end
end
