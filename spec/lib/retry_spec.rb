# frozen_string_literal: true

RSpec.describe Retry do
  after { described_class.unregister(:test) }

  let(:registered) { described_class.instance_variable_get(:@retry_types) }

  describe '.register' do
    context 'when correct registration with a single class' do
      before { described_class.register(:test, StandardError) }

      it { expect(registered).to include(test: [StandardError]) }
    end

    context 'when correct registration with array' do
      before { described_class.register(:test, [StandardError, OpenSSL::SSL::SSLError]) }

      it do
        expect(registered[:test]).to contain_exactly(StandardError, OpenSSL::SSL::SSLError)
      end
    end

    context 'when try to register a duplicate' do
      before { described_class.register(:test, StandardError) }

      it do
        expect { described_class.register(:test, StandardError) }.to raise_error(/already registered/)
      end
    end

    context 'when try to pass a wrong class' do
      it do
        expect { described_class.register(:test, [StandardError, Integer]) }.
          to raise_error('Integer is not an Exception class')
      end
    end

    context 'when try to register an empty list' do
      it do
        expect { described_class.register(:test, nil) }.to raise_error(/no exception class provided/)
      end
    end
  end

  describe '.for' do
    subject(:action!) do
      described_class.for(:test, intervals: [0, 0]) { HTTP.get('http://e1.ru').body.to_s }
    end

    before { described_class.register(:test, [HTTP::Error, OpenSSL::SSL::SSLError]) }

    context 'when exception from the list' do
      let!(:http_stub) do
        stub_request(:get, 'http://e1.ru').
          to_raise(OpenSSL::SSL::SSLError).
          then.
          to_return(body: 'test')
      end

      it do
        expect { action! }.not_to raise_error

        expect(action!).to eq('test')
        expect(http_stub).to have_been_requested.twice
      end
    end

    context 'when exception out of the list' do
      let!(:http_stub) do
        stub_request(:get, 'http://e1.ru').
          to_raise(StandardError.new('here')).
          then.
          to_return(body: 'test')
      end

      it do
        expect { action! }.to raise_error('here')

        expect(http_stub).to have_been_requested.once
      end
    end

    context 'when too many attempts' do
      let!(:http_stub) do
        stub_request(:get, 'http://e1.ru').
          to_raise(OpenSSL::SSL::SSLError).
          then.
          to_raise(OpenSSL::SSL::SSLError).
          then.
          to_raise(OpenSSL::SSL::SSLError).
          then.
          to_return(body: 'test')
      end

      it do
        expect { action! }.to raise_error(OpenSSL::SSL::SSLError)

        expect(http_stub).to have_been_requested.times(3)
      end
    end
  end
end
