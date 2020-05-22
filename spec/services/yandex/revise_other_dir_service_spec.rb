# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Yandex::ReviseOtherDirService do
  let(:token) { create :'yandex/token', other_dir: '/other', access_token: API_ACCESS_TOKEN }

  before do
    create :track, local_filename: 'test'

    create :track, storage_filename: '100629933dd18a31a7bc895ec04ee18fa70f15266512.gpx',
                   size: 3_801_113,
                   md5: 'd01370991b04c6089763ae93c4ae9799',
                   yandex_token: token

    create :track, storage_filename: '1007fcb25a39fb7254397755506edee33cd602e27714.gpx',
                   size: 1_984_394,
                   md5: '9d23b5658fb6c202e54b48f65b8ca35e',
                   yandex_token: token
  end

  context 'when dir does not exists' do
    subject(:service_context) do
      VCR.use_cassette('yandex_revise_others_wrong_dir') { described_class.call!(token: token) }
    end

    let(:token) { create :'yandex/token', other_dir: '/other1', access_token: API_ACCESS_TOKEN }

    it do
      expect(service_context).to be_a_success

      expect(service_context.errors.keys).to eq([nil])
      expect(service_context.errors[nil]).to eq(['dir /other1 not found on remote storage'])
    end
  end

  context 'when dir exists' do
    subject(:service_context) do
      VCR.use_cassette('yandex_revise_other_dir') { described_class.call!(token: token) }
    end

    context 'when track does not exist in database' do
      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq([nil])
        expect(service_context.errors[nil]).to eq(['1008c271d57b9d519ba2d304bdb8584ed1666dc64069.gpx'])
      end
    end

    context 'when track does not exist on remote storage' do
      before do
        create :track, storage_filename: '1008c271d57b9d519ba2d304bdb8584ed1666dc64069.gpx',
                       size: 3_780_953,
                       md5: 'a568fedd7b0b3224611a3e29a9127c21',
                       yandex_token: token
      end

      let!(:track4) { create :track, storage_filename: 'test.gpx', yandex_token: token }

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq([track4.id])
        expect(service_context.errors[track4.id]).to eq(['not found on remote storage'])
      end
    end

    context 'when wrong track info' do
      let!(:track3) do
        create :track, storage_filename: '1008c271d57b9d519ba2d304bdb8584ed1666dc64069.gpx',
                       size: 3_780_954,
                       md5: 'a568fedd7b0b3224611a3e29a9127c22',
                       yandex_token: token
      end

      it do
        expect(service_context).to be_a_success

        expect(service_context.errors.keys).to eq([track3.id])
        expect(service_context.errors[track3.id]).to match_array(['size mismatch', 'etag mismatch'])
      end
    end

    context 'when without errors' do
      before do
        create :track, storage_filename: '1008c271d57b9d519ba2d304bdb8584ed1666dc64069.gpx',
                       size: 3_780_953,
                       md5: 'a568fedd7b0b3224611a3e29a9127c21',
                       yandex_token: token
      end

      it do
        expect(service_context).to be_a_success
        expect(service_context.errors).to be_empty
      end
    end
  end
end
