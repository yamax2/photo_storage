require 'rails_helper'

RSpec.describe Yandex::CreateOrUpdateTokenService do
  let(:code) { '5851358' }
  let(:service_context) { described_class.call!(code: code) }

  context 'when token does not exist' do
    subject do
      VCR.use_cassette('create_new_token') { service_context }
    end

    it do
      expect { subject }.to change { Yandex::Token.count }.by(1)

      expect(service_context.token).to have_attributes(active: false, user_id: String)
    end
  end

  context 'when token for client already exists' do
    let!(:token) { create :'yandex/token', user_id: '1130000019982670' }

    subject do
      VCR.use_cassette('create_new_token') { service_context }
    end

    it do
      expect { subject }.to change { Yandex::Token.count }.by(0).
        and change { token.reload.access_token }
    end
  end

  context 'when yandex api is unreachable' do
    before { stub_request(:any, /oauth.yandex.ru/).to_timeout }

    it do
      expect { service_context }.to raise_error(Net::OpenTimeout)
    end
  end
end
