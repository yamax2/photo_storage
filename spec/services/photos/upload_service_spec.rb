require 'rails_helper'

RSpec.describe Photos::UploadService do
  let(:service_context) { described_class.call(photo: photo) }

  context 'when file already uploaded' do
    let(:photo) { create :photo, storage_filename: 'test.jpg' }

    it { expect(service_context).to be_a_success }
  end

  context 'when local_filename is empty' do
    let(:photo) { create :photo }

    it { expect(service_context).to be_a_success }
  end

  context 'when active token does not exist' do
    let(:photo) { create :photo, local_filename: 'test' }

    it do
      expect(service_context).to be_a_failure
      expect(service_context.message).to eq('active token not found')
    end
  end

  context 'when correct upload' do
    let(:photo) { create :photo, local_filename: 'cats.jpg' }
    let!(:tmp_file) { photo.tmp_local_filename }

    let!(:yandex_token) do
      create :'yandex/token', access_token: API_ACCESS_TOKEN,
                              active: true,
                              dir: '/test_photos',
                              other_dir: '/other_dir'
    end

    before do
      allow(SecureRandom).to receive(:hex).and_return('94942206a2a4eeb5015938089a066720bd919f27')
      allow(photo).to receive(:id).and_return(368)

      FileUtils.cp('spec/fixtures/cats.jpg', photo.tmp_local_filename)
    end

    context 'and to a new folder' do
      subject do
        VCR.use_cassette('photo_upload_new_folder') { service_context }
      end

      it do
        expect { subject }.
          to change { photo.storage_filename }.from(nil).to(String).
          and change { photo.local_filename }.from(String).to(nil).
          and change { photo.yandex_token_id }.from(nil).to(yandex_token.id)

        expect(service_context).to be_a_success
        expect(File.exist?(tmp_file)).to eq(false)
        expect(photo).not_to be_changed
      end
    end

    context 'and to an existing folder' do
      before do
        VCR.use_cassette('photo_upload_old_folder') { service_context }
      end

      it do
        expect(service_context).to be_a_success
        expect(File.exist?(tmp_file)).to eq(false)
        expect(photo).not_to be_changed
      end
    end

    context 'and api is unreachable' do
      before { stub_request(:any, /webdav.yandex.ru/).to_timeout }
      after { FileUtils.rm_f(tmp_file) }

      it do
        expect { service_context }.to raise_error(Net::OpenTimeout)
      end
    end
  end
end
