# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProxySessionService do
  context 'when proxy.secret is unassigned' do
    before do
      allow(Rails.application.credentials).to receive(:proxy).and_return({})
    end

    it do
      expect { described_class.new }.to raise_error(/proxy.secret/)
    end
  end

  context 'when correct settings' do
    subject { described_class.new(current_session).call }

    before do
      allow(Rails.application.credentials.proxy).to receive(:fetch).with(:secret).and_return('secret')
      allow(Rails.application.routes.default_url_options).to receive(:[]).with(:host).and_return('example.com')
    end

    context 'when current session is nil' do
      let(:current_session) { nil }

      it { is_expected.not_to be_empty }
    end

    context 'when session is not expired' do
      before { Timecop.freeze }
      after { Timecop.return }

      let(:current_session) { generate_proxy_session({started: Time.current.to_i}.to_json) }

      it { is_expected.to be_nil }
    end

    context 'when session is expired' do
      before { Timecop.freeze }
      after { Timecop.return }

      let(:current_session) { generate_proxy_session({started: 2.months.to_i}.to_json) }

      it do
        is_expected.not_to be_empty
        is_expected.not_to eq(current_session)
      end
    end

    context 'when call with incorrect current session' do
      context 'and value is empty' do
        let(:current_session) { '' }

        it { is_expected.not_to be_empty }
      end

      context 'and value is spaces' do
        let(:current_session) { '  ' }

        it { expect(subject.strip).not_to be_empty }
      end

      context 'and value is not a base64 string' do
        let(:current_session) { 'zz' }

        it do
          is_expected.not_to be_empty
          is_expected.not_to eq(current_session)
        end
      end

      context 'and value is incorrect json' do
        let(:current_session) { generate_proxy_session('zozo') }

        it do
          is_expected.not_to be_empty
          is_expected.not_to eq(current_session)
        end
      end

      context 'and without "started" key' do
        let(:current_session) { generate_proxy_session({qq: :zozo}.to_json) }

        it do
          is_expected.not_to be_empty
          is_expected.not_to eq(current_session)
        end
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
