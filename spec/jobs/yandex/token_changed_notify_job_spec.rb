# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Yandex::TokenChangedNotifyJob do
  around { |example| Sidekiq::Testing.inline! { example.run } }

  let(:reload_url) { "#{Rails.application.proxy_url}/reload" }

  context 'when success' do
    subject do
      VCR.use_cassette('yandex_token_changed') do
        described_class.perform_async
        described_class.drain
      end
    end

    it do
      expect { subject }.not_to raise_error

      expect(WebMock).to have_requested(:get, reload_url) { |req| req.headers.include?('Cookie') }
    end
  end

  context 'when failed' do
    before { stub_request(:get, reload_url).to_timeout }

    subject do
      described_class.perform_async
      described_class.drain
    end

    it do
      expect { subject }.to raise_error(Net::OpenTimeout)
    end
  end
end
