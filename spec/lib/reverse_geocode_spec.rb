require 'rails_helper'

RSpec.describe Nominatim::ReverseGeocode do
  context 'when successful request' do
    subject do
      VCR.use_cassette('nominatim_reverse_geocode_success') do
        described_class.new(lat: 57.3099288888889, long: 56.9759902777778).call
      end
    end

    it do
      expect(subject.fetch(:display_name)).to match(/Голдыревское сельское поселение/)
    end
  end

  context 'when failed request' do
    subject do
      VCR.use_cassette('nominatim_reverse_geocode_failed') do
        described_class.new(lat: 57.3099288888889, long: 1111156).call
      end
    end

    it do
      expect { subject }.
        to raise_error(described_class::Error, 'nominatim request failed: Unable to geocode, code: ')
    end
  end

  context 'when too many requests' do
    before do
      stub_request(:any, /nominatim.openstreetmap.org/).to_return(status: 429, body: 'Too many requests')
    end

    it do
      expect { described_class.new(lat: 1, long: 2).call }.
        to raise_error(described_class::Error, 'nominatim request failed: Too many requests, code: 429')
    end
  end

  context 'when api is unreachable' do
    before { stub_request(:any, /nominatim.openstreetmap.org/).to_timeout }

    it do
      expect { described_class.new(lat: 1, long: 2).call }.to raise_error(Net::OpenTimeout)
    end
  end
end
