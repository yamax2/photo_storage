# frozen_string_literal: true

RSpec.describe Tracks::UploadService do
  let(:service_context) { described_class.call(track: track) }

  before { FileUtils.mkdir_p(Rails.root.join('tmp/files')) }

  context 'when file already uploaded' do
    let(:token) { create :'yandex/token' }
    let(:track) { create :track, storage_filename: 'test.gpx', yandex_token: token }

    it { expect(service_context).to be_a_success }
  end

  context 'when local file does not exist' do
    let(:track) { create :track, local_filename: 'test23.gpx' }

    it do
      expect(service_context).to be_a_failure
      expect(service_context.message).to eq('local file not found')
    end
  end

  context 'when real upload' do
    let(:track) { build :track, local_filename: 'test1.gpx' }
    let!(:tmp_file) { track.tmp_local_filename }

    let(:yandex_token) do
      create :'yandex/token', access_token: API_ACCESS_TOKEN,
                              active: true,
                              dir: '/test_photos',
                              other_dir: '/other'
    end

    before do
      allow(StorageFilenameGenerator).to receive(:call).and_return('36894942206a2a4eeb5015938089a066720bd919f27.gpx')

      yandex_token

      FileUtils.cp('spec/fixtures/test1.gpx', track.tmp_local_filename)
      track.save!
    end

    context 'and success' do
      subject(:upload!) { VCR.use_cassette('track_upload1') { service_context } }

      it do
        expect { upload! }.to change(track, :storage_filename).from(nil).to(String).
          and change(track, :local_filename).from(String).to(nil).
          and change(track, :yandex_token_id).from(nil).to(yandex_token.id)

        expect(File.exist?(tmp_file)).to eq(false)
        expect(track).not_to be_changed
      end
    end

    context 'and active token does not exist' do
      let(:yandex_token) { nil }

      it do
        expect(service_context).to be_a_failure
        expect(service_context.message).to eq('active token not found')
      end
    end

    context 'and api is unreachable' do
      before { stub_request(:any, /webdav.yandex.ru/).to_timeout }

      after { FileUtils.rm_f(tmp_file) }

      it do
        expect { service_context }.to raise_error(Net::OpenTimeout)
      end
    end

    context 'and remote filename generated externally' do
      let(:storage_filename) { 'new_filename' }
      let(:service_context) { described_class.call(track: track, storage_filename: storage_filename) }

      before { stub_request(:any, /webdav.yandex.ru/).to_return(body: '') }

      it do
        expect { service_context }.to change { track.reload.storage_filename }.to(storage_filename)
      end
    end
  end
end
