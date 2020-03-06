# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProxySessionService do
  context 'when without proxy session settings' do
    before do
      allow(Rails.application.config).to receive(:proxy).and_return(nil)
    end

    it do
      expect { described_class.new }.to raise_error(/proxy.secret/)
    end
  end

  context 'when proxy secrets unassigned' do
    before do
      allow(Rails.application.config).to receive(:proxy).and_return({})
    end

    it do
      expect { described_class.new }.to raise_error(/proxy.secret/)
    end
  end

  context 'when correct settings' do
    subject { described_class.new(current_session).call }

    before do
      allow(Rails.application.config).to receive(:proxy).and_return(secret: 'secret', iv: '389ed464a551f644')
      Timecop.freeze
    end

    after { Timecop.return }

    context 'when current session is nil' do
      let(:current_session) { nil }

      it { is_expected.to eq(generate_proxy_session) }
    end

    context 'when session is not expired' do
      let(:current_session) { generate_proxy_session(1.month.from_now.to_i) }

      it { is_expected.to be_nil }
    end

    context 'when session is expired' do
      let(:current_session) { generate_proxy_session(1.day.ago.to_i) }

      it do
        is_expected.not_to be_empty
        is_expected.not_to eq(current_session)
      end
    end

    context 'when call with incorrect current session' do
      context 'and value is empty' do
        let(:current_session) { '' }

        it { is_expected.to eq(generate_proxy_session) }
      end

      context 'and value is spaces' do
        let(:current_session) { '  ' }

        it { expect(subject.strip).to eq(generate_proxy_session) }
      end

      context 'and value is not a base64 string' do
        let(:current_session) { 'zz' }

        it { is_expected.to eq(generate_proxy_session) }
      end

      context 'and value is incorrect json' do
        let(:current_session) { generate_proxy_session(custom_json: 'zozo') }

        it { is_expected.to eq(generate_proxy_session) }
      end

      context 'and without "till" key' do
        let(:current_session) { generate_proxy_session(custom_json: {qq: :zozo}) }

        it { is_expected.to eq(generate_proxy_session) }
      end

      context 'and wrong md5 sign' do
        let(:current_session) do
          session = generate_proxy_session(1.month.from_now.to_i)

          Base64.encode64(Digest::MD5.digest('zozo') + Base64.decode64(session)[16..-1]).gsub(/[[:space:]]/, '')
        end

        it { is_expected.to eq(generate_proxy_session) }
      end

      context 'and unknown error' do
        let(:current_session) { 'zozo' }

        before do
          allow(Time).to receive(:current).and_raise('boom!')
        end

        it do
          expect { subject }.to raise_error('boom!')
        end
      end
    end
  end
end
