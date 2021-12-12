# frozen_string_literal: true

RSpec.describe Yandex::RemoveFileJob do
  let(:node) { create :'yandex/token', access_token: API_ACCESS_TOKEN }

  context 'when a wrong node' do
    subject(:remove!) { described_class.new.perform(1, '/1/test.mp4') }

    it do
      expect { remove! }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when file exists' do
    subject(:remove!) do
      VCR.use_cassette('yandex_remove_success') do
        described_class.new.perform(node.id, '/1/test.mp4')

        YandexClient::Dav[node.access_token].propfind('/1/')
      end
    end

    it do
      expect { remove! }.not_to raise_error

      expect(remove!.select(&:file?)).to be_empty
    end
  end

  context 'when file does not exist' do
    subject(:remove!) do
      VCR.use_cassette('yandex_remove_404') { described_class.new.perform(node.id, 'test.mp4') }
    end

    it { expect { remove! }.not_to raise_error }
  end

  context 'when other error' do
    subject(:remove!) { described_class.new.perform(node.id, 'test.mp4') }

    before { stub_request(:any, /webdav.yandex.ru/).to_timeout }

    it do
      expect { remove! }.to raise_error(HTTP::TimeoutError)
    end
  end
end
