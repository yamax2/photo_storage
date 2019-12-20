# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tracks::EnqueueProcessService do
  let(:track) { build :track }
  let(:service_context) { described_class.call(model: track, uploaded_io: gpx) }
  let(:tmp_filename) { Rails.root.join('tmp', 'files', track.local_filename) }

  before do
    allow(Tracks::ProcessFileJob).to receive(:perform_async)
  end

  after { FileUtils.rm_f(tmp_filename) }

  context 'when wrong mime' do
    let(:gpx) { fixture_file_upload('spec/fixtures/test2.jpg', 'image/jpeg') }

    it do
      expect(service_context).to be_a_failure
      expect(track).not_to be_persisted
      expect(track.errors).to include(:content_type)
      expect(File.exist?(tmp_filename)).to eq(false)

      expect(Tracks::ProcessFileJob).not_to have_received(:perform_async)
    end
  end

  context 'when correct mime' do
    let(:gpx) { fixture_file_upload('spec/fixtures/test1.gpx', 'application/gpx+xml') }

    it do
      expect(service_context).to be_a_success
      expect(track).to be_persisted
      expect(track.errors).to be_empty

      expect(track.local_filename).to be_present
      expect(track.md5).to be_present
      expect(track.sha256).to be_present

      expect(track).to have_attributes(original_filename: 'test1.gpx', size: 1_453_201)

      expect(File.exist?(tmp_filename)).to eq(true)

      expect(Tracks::ProcessFileJob).to have_received(:perform_async).with(track.id)
    end
  end

  context 'when track with incorrect name' do
    let(:track) { build :track, name: '' }
    let(:gpx) { fixture_file_upload('spec/fixtures/test1.gpx', 'application/gpx+xml') }

    it do
      expect(service_context).to be_a_failure
      expect(track).not_to be_persisted
      expect(track.errors).to include(:name)
      expect(File.exist?(tmp_filename)).to eq(false)

      expect(Tracks::ProcessFileJob).not_to have_received(:perform_async)
    end
  end
end
