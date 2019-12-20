# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Yandex::RefreshTokenService do
  before { Timecop.freeze }

  let(:valid_till) { 1.day.from_now }
  let(:token) { create :'yandex/token', refresh_token: API_REFRESH_TOKEN, valid_till: valid_till }

  after { Timecop.return }

  let(:service_context) { described_class.call!(token: token) }

  context 'when requires refresh' do
    context 'regular call' do
      subject do
        VCR.use_cassette('refresh_token') { service_context }
      end

      it do
        expect { subject }.to change { token.reload.refresh_token }.and(change { token.valid_till })
      end
    end

    context 'and api is unreachable' do
      before { stub_request(:any, /oauth.yandex.ru/).to_timeout }

      it do
        expect { service_context }.to raise_error(Net::OpenTimeout)
      end
    end
  end

  context 'when refresh does not need' do
    let(:valid_till) { 5.days.from_now }

    it do
      expect { subject }.not_to(change { token.reload })
    end
  end
end
