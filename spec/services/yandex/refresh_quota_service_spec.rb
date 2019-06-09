require 'rails_helper'

RSpec.describe Yandex::RefreshQuotaService do
  let(:token) { create :'yandex/token', access_token: API_ACCESS_TOKEN }
  let(:service_context) { described_class.call!(token: token) }

  context 'regular call' do
    subject do
      VCR.use_cassette('refresh_quota') { service_context }
    end

    it do
      expect { subject }.to(change { token.reload.used_space }.and(change{ token.total_space }))
    end
  end

  context 'when api is unreachable' do
    before { stub_request(:any, /webdav.yandex.ru/).to_timeout }

    it do
      expect { service_context }.to raise_error(Net::OpenTimeout)
    end
  end
end
