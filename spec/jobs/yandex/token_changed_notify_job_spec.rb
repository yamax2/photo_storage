# frozen_string_literal: true

RSpec.describe Yandex::TokenChangedNotifyJob do
  let(:reload_url) { Rails.application.routes.url_helpers.proxy_reload_url }

  context 'when success' do
    subject(:request) do
      VCR.use_cassette('yandex_token_changed') { described_class.new.perform }
    end

    it do
      expect { request }.not_to raise_error

      expect(WebMock).to have_requested(:get, reload_url)
    end
  end

  context 'when failed' do
    subject(:request) { described_class.new.perform }

    before { stub_request(:get, reload_url).to_timeout }

    it do
      expect { request }.to raise_error(Net::OpenTimeout)
    end
  end
end
