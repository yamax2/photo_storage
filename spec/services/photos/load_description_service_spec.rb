# frozen_string_literal: true

RSpec.describe Photos::LoadDescriptionService do
  context 'when photo with lat_long' do
    context 'and description is not loaded' do
      let(:photo) { create :photo, lat_long: [57.3099288888889, 56.9759902777778], local_filename: 'test' }

      let(:service_context) do
        VCR.use_cassette('nominatim_reverse_geocode_success') { described_class.call!(photo: photo) }
      end

      it do
        expect { service_context }.
          to change { photo.reload.description }.from(nil).to(/Голдыревское сельское поселение/)
      end
    end

    context 'and description already loaded' do
      let(:photo) { create :photo, lat_long: [57.30, 56.97], local_filename: 'test', description: 'test' }
      let(:service_context) { described_class.call!(photo: photo) }

      it do
        expect { service_context }.not_to(change { photo.reload.description })
      end
    end
  end

  context 'when photo without lat_long' do
    let(:photo) { create :photo, local_filename: 'test' }
    let(:service_context) { described_class.call!(photo: photo) }

    it do
      expect { service_context }.not_to(change { photo.reload.description })
    end
  end
end
