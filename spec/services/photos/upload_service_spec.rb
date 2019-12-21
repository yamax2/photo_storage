# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Photos::UploadService do
  let(:service_context) { described_class.call(photo: photo) }
  before { FileUtils.mkdir_p(Rails.root.join('tmp/files')) }

  context 'when file already uploaded' do
    let(:token) { create :'yandex/token' }
    let(:photo) { create :photo, storage_filename: 'test.jpg', yandex_token: token }

    it { expect(service_context).to be_a_success }
  end

  context 'when local file does not exist' do
    let(:photo) { create :photo, local_filename: 'test23.jpg' }

    it do
      expect(service_context).to be_a_failure
      expect(service_context.message).to eq('local file not found')
    end
  end

  context 'when real upload' do
    let(:photo) { build :photo, local_filename: 'cats.jpg' }
    let!(:tmp_file) { photo.tmp_local_filename }

    let!(:yandex_token) do
      create :'yandex/token', access_token: API_ACCESS_TOKEN,
                              active: true,
                              dir: '/test_photos',
                              other_dir: '/other_dir'
    end

    before do
      allow_any_instance_of(StorageFilenameGenerator).
        to receive(:call).and_return('000/000/36894942206a2a4eeb5015938089a066720bd919f27')

      FileUtils.cp('spec/fixtures/cats.jpg', photo.tmp_local_filename)
      photo.save!
    end

    context 'and active token does not exist' do
      let!(:yandex_token) { nil }

      it do
        expect(service_context).to be_a_failure
        expect(service_context.message).to eq('active token not found')
      end
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

    context 'and to a new sub_folder' do
      subject do
        VCR.use_cassette('photo_upload_new_sub_folder') { service_context }
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
