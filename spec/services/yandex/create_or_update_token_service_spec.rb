# frozen_string_literal: true

RSpec.describe Yandex::CreateOrUpdateTokenService do
  let(:code) { '5851358' }
  let(:service_context) { described_class.call!(code: code) }

  context 'when token does not exist' do
    subject(:update!) do
      VCR.use_cassette('create_new_token') { service_context }
    end

    it do
      expect(Yandex::RefreshTokenJob).to receive(:perform_async).with(Integer)

      expect { update! }.to change(Yandex::Token, :count).by(1)

      expect(service_context.token).to have_attributes(active: false, user_id: String)
    end
  end

  context 'when token for client already exists' do
    subject(:update!) do
      VCR.use_cassette('create_new_token') { service_context }
    end

    let!(:token) { create :'yandex/token', user_id: '1130000019982670' }

    it do
      expect(Yandex::RefreshTokenJob).to receive(:perform_async).with(token.id)

      expect { update! }.to change(Yandex::Token, :count).by(0).and(change { token.reload.access_token })
    end
  end

  context 'when no need to change token' do
    let(:token) do
      create :'yandex/token', user_id: '1130000019982670',
                              login: 'max@mail.mytm.tk',
                              access_token: 'access_token',
                              refresh_token: 'refresh_token',
                              valid_till: Time.zone.local(2017, 1, 1) + 10.seconds
    end

    before do
      stub_request(:post, 'https://oauth.yandex.ru/token').to_return(
        body: {
          token_type: :bearer,
          access_token: :access_token,
          expires_in: 10.seconds,
          refresh_token: :refresh_token
        }.to_json
      )

      stub_request(:get, 'https://login.yandex.ru/info').to_return(
        body: {
          client_id: '99bcbd17ad7f411694710592d978a4a2',
          login: 'max@mail.mytm.tk',
          id: '1130000019982670'
        }.to_json
      )

      Timecop.freeze Time.zone.local(2017, 1, 1)

      token
    end

    after { Timecop.return }

    it do
      expect(Yandex::RefreshTokenJob).not_to receive(:perform_async)

      expect { service_context }.not_to change(token, :reload)
    end
  end

  context 'when yandex api is unreachable' do
    before { stub_request(:any, /oauth.yandex.ru/).to_timeout }

    it do
      expect(Yandex::RefreshTokenJob).not_to receive(:perform_async)

      expect { service_context }.to raise_error(HTTP::TimeoutError)
    end
  end
end
