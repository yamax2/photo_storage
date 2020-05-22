# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tracks::RemoveService do
  let(:token) { create :'yandex/token', access_token: API_ACCESS_TOKEN, other_dir: '/other' }
  let(:service_context) do
    described_class.call!(
      storage_filename: '2019-05-02_15-28_Thu.gpx',
      yandex_token: token
    )
  end

  context 'when file exists' do
    subject(:remove!) { VCR.use_cassette('track_remove_success') { service_context } }

    it do
      expect { remove! }.not_to raise_error
    end
  end

  context 'when file does not exist' do
    subject(:remove!) { VCR.use_cassette('track_remove_404') { service_context } }

    it do
      expect { remove! }.not_to raise_error
    end
  end

  context 'when other error' do
    before { stub_request(:any, /webdav.yandex.ru/).to_timeout }

    it do
      expect { service_context }.to raise_error(Net::OpenTimeout)
    end
  end
end
