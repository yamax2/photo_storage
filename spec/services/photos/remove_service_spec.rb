# frozen_string_literal: true

RSpec.describe Photos::RemoveService do
  let(:token) { create :'yandex/token', access_token: API_ACCESS_TOKEN, dir: '/test' }
  let(:service_context) { described_class.call!(storage_filename: 'IMG_20190501_142011.jpg', yandex_token: token) }

  context 'when file exists' do
    subject(:remove!) { VCR.use_cassette('photo_remove_success') { service_context } }

    it do
      expect { remove! }.not_to raise_error
    end
  end

  context 'when file does not exist' do
    subject(:remove!) { VCR.use_cassette('photo_remove_404') { service_context } }

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
