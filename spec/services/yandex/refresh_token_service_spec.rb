# frozen_string_literal: true

RSpec.describe Yandex::RefreshTokenService do
  before { Timecop.freeze(2020, 1, 1) }

  let(:valid_till) { 1.day.from_now }
  let(:token) { create :'yandex/token', refresh_token: API_REFRESH_TOKEN, valid_till: }
  let(:service_context) { described_class.call!(token:) }

  after { Timecop.return }

  context 'when requires refresh' do
    context 'regular call' do
      subject(:refresh!) do
        VCR.use_cassette('refresh_token') { service_context }
      end

      it do
        expect { refresh! }.to change { token.reload.refresh_token }.and change(token, :valid_till)
      end
    end

    context 'when without changes' do
      let(:token) { create :'yandex/token', refresh_token: :new_token, valid_till: 10.minutes.from_now }

      before do
        stub_request(:post, 'https://oauth.yandex.ru/token').to_return(
          body: {
            token_type: :bearer,
            access_token: :access_token,
            expires_in: 10.minutes.to_i,
            refresh_token: :new_token
          }.to_json
        )
      end

      it do
        expect { service_context }.not_to change(token, :reload)
      end
    end

    context 'and api is unreachable' do
      before { stub_request(:any, /oauth.yandex.ru/).to_timeout }

      it do
        expect { service_context }.to raise_error(HTTP::TimeoutError)
      end
    end
  end

  context 'when refresh does not need' do
    let(:valid_till) { 5.days.from_now }

    it do
      expect { service_context }.not_to change(token, :reload)
    end
  end
end
