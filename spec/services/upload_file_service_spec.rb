# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadFileService do
  let(:gpx) { fixture_file_upload('spec/fixtures/test1.gpx', 'application/gpx+xml') }
  let(:dir) { Rails.root.join('tmp/files') }

  before do
    allow(SecureRandom).to receive(:hex).and_return('test')
  end

  after { FileUtils.rm_rf(dir) }

  context 'when first call' do
    before { FileUtils.rm_rf(dir) }

    it do
      expect { described_class.move(gpx) }.
        to change { File.exist?(dir.join('test')) }.from(false).to(true).
        and change { Dir.exist?(dir) }.from(false).to(true)
    end
  end

  context 'when temporary dir exists' do
    before { FileUtils.mkdir_p(dir) }

    it do
      expect { described_class.move(gpx) }.to change { File.exist?(dir.join('test')) }.from(false).to(true)
    end
  end
end
