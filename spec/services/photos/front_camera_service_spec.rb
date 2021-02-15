# frozen_string_literal: true

RSpec.describe Photos::FrontCameraService do
  before do
    allow(Rails.application.config).to receive(:front_cameras).and_return(config)
  end

  let(:photo) { build :photo, exif: exif, width: 2_000, height: 1_000, local_filename: 'test.jpg' }
  let(:service_context) { described_class.call(photo: photo) }
  let(:exif) { {make: 'HUAWEI', model: 'CLT-L29'} }

  context 'when without config' do
    let(:config) { nil }

    it do
      expect { service_context }.not_to change(photo, :props)

      expect(service_context).to be_a_success
      expect(photo).not_to be_persisted
    end
  end

  context 'when without config for camera' do
    let(:config) do
      [
        {
          make: 'ZOZO',
          model: 'TEST'
        }
      ]
    end

    it do
      expect { service_context }.not_to change(photo, :props)

      expect(service_context).to be_a_success
      expect(photo).not_to be_persisted
    end
  end

  context 'when config for model is wrong' do
    let(:config) do
      [
        {
          make: 'HUAWEI',
          model: 'CLT-L29'
        }
      ]
    end

    it do
      expect { service_context }.to raise_error(KeyError)
    end
  end

  context 'when photo does not pass filter' do
    let(:config) do
      [
        {
          make: 'HUAWEI',
          model: 'CLT-L29',
          dimension: 100
        }
      ]
    end

    it do
      expect { service_context }.not_to change(photo, :props)

      expect(service_context).to be_a_success
      expect(photo).not_to be_persisted
    end
  end

  context 'when photo passes filter' do
    let(:config) do
      [
        {
          make: 'HUAWEI',
          model: 'CLT-L29',
          dimension: 1_000,
          effects: %w[
            scaleX(-1)
          ],
          rotated: 1
        }
      ]
    end

    it do
      expect { service_context }.
        to change(photo, :effects).from(nil).to(%w[scaleX(-1)]).
        and change(photo, :rotated).from(nil).to(1)

      expect(service_context).to be_a_success
      expect(photo).to be_persisted
    end
  end

  context 'when no actions' do
    let(:config) do
      [
        {
          make: 'HUAWEI',
          model: 'CLT-L29',
          dimension: 1_000
        }
      ]
    end

    it do
      expect { service_context }.not_to change(photo, :props)

      expect(service_context).to be_a_success
      expect(photo).to be_persisted
    end
  end
end
