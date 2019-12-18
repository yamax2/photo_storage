# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Admin::TracksController do
  render_views

  describe '#create' do
    context 'when wrong rubric' do
      let(:track) { fixture_file_upload('spec/fixtures/test1.gpx', 'application/gpx+xml') }

      it do
        expect { post :create, params: {rubric_id: 1, content: track}, xhr: true }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when without content param' do
      subject { post :create, params: {rubric_id: 1}, xhr: true }

      it do
        expect { subject }.to raise_error(ActionController::ParameterMissing).with_message(/content/)
      end
    end

    context 'when without rubric_id param' do
      let(:track) { fixture_file_upload('spec/fixtures/test1.gpx', 'application/gpx+xml') }

      subject { post :create, params: {content: track}, xhr: true }

      it do
        expect { subject }.to raise_error(ActionController::ParameterMissing).with_message(/rubric_id/)
      end
    end

    context 'when successful upload' do
      let(:rubric) { create :rubric }
      let(:track) { fixture_file_upload('spec/fixtures/test1.gpx', 'application/gpx+xml') }

      let(:json) { JSON.parse(response.body) }

      context 'when without external info' do
        before { post :create, params: {rubric_id: rubric.id, content: track}, xhr: true }

        it do
          expect(response).to have_http_status(:ok)
          expect(json).to include('id')
        end
      end

      after do
        Track.all.each { |track| FileUtils.rm_f(track.tmp_local_filename) }
      end
    end

    context 'when error on upload' do
      let(:rubric) { create :rubric }
      let(:track) { fixture_file_upload('spec/fixtures/test.txt', 'text/plain') }

      before { post :create, params: {rubric_id: rubric.id, content: track}, xhr: true }

      it do
        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)).to include('content_type')
      end

      after { FileUtils.rm_rf(Rails.root.join('tmp', 'files').to_s) }
    end
  end
end
