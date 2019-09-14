require 'rails_helper'

RSpec.describe Admin::PhotosController do
  render_views

  describe '#create' do
    context 'when without image param' do
      subject { post :create, params: {rubric_id: 1}, xhr: true }

      it do
        expect { subject }.to raise_error(ActionController::ParameterMissing).with_message(/image/)
      end
    end

    context 'when without rubric_id param' do
      subject { post :create, params: {image: 'test'}, xhr: true }

      it do
        expect { subject }.to raise_error(ActionController::ParameterMissing).with_message(/rubric_id/)
      end
    end

    context 'when successful upload' do
      let(:rubric) { create :rubric }
      let(:image) { fixture_file_upload('spec/fixtures/test2.jpg', 'image/jpeg') }

      let(:json) { JSON.parse(response.body) }

      context 'when without external info' do
        before { post :create, params: {rubric_id: rubric.id, image: image}, xhr: true }

        it do
          expect(response).to have_http_status(:ok)
          expect(json).to include('id')
        end
      end

      context 'when with external info' do
        before { post :create, params: {rubric_id: rubric.id, image: image, external_info: 'test'}, xhr: true }

        let(:photo) { assigns(:photo) }

        it do
          expect(response).to have_http_status(:ok)
          expect(json.keys).to match_array(%w[id])

          expect(json['id']).to eq(photo.id)
          expect(photo.external_info).to eq('test')
        end
      end

      after do
        Photo.all.each { |photo| FileUtils.rm_f(photo.tmp_local_filename) }
      end
    end

    context 'when error on upload' do
      let(:rubric) { create :rubric }
      let(:image) { fixture_file_upload('spec/fixtures/test.txt', 'text/plain') }

      before { post :create, params: {rubric_id: rubric.id, image: image}, xhr: true }

      it do
        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)).to include('content_type')
      end

      after { FileUtils.rm_rf(Rails.root.join('tmp', 'files').to_s) }
    end
  end
end
