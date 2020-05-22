# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::RubricsController do
  render_views

  let(:json) { JSON.parse(response.body) }

  describe '#show' do
    context 'when wrong rubric' do
      before { get :show, params: {id: 1, offset: 1, limit: 5} }

      it do
        expect(response).to have_http_status(:ok)
        expect(json).to be_empty
      end
    end

    context 'when correct rubric' do
      let(:root_rubric) { create :rubric }
      let(:rubric) { create :rubric, rubric: root_rubric }
      let(:token) { create :'yandex/token' }

      let!(:photo1) do
        create :photo, rubric: rubric, yandex_token: token, storage_filename: 'test', width: 100, height: 100
      end

      let!(:photo2) do
        create :photo, rubric: rubric,
                       yandex_token: token,
                       storage_filename: 'test',
                       width: 100,
                       height: 100,
                       lat_long: [1, 2]
      end

      context 'and with limit' do
        before { get :show, params: {id: rubric.id, offset: 1, limit: 1} }

        it do
          expect(response).to have_http_status(:ok)
          expect(json).to match_array(
            [hash_including('url', 'image_size', 'preview', 'id' => photo2.id, 'rn' => 2)]
          )
        end
      end

      context 'when without limits' do
        before { get :show, params: {id: rubric.id} }

        it do
          expect(response).to have_http_status(:ok)

          expect(json).to match_array(
            [
              hash_including('id' => photo1.id),
              hash_including('id' => photo2.id)
            ]
          )
        end
      end

      context 'when only_with_geo_tags' do
        before { get :show, params: {id: rubric.id, only_with_geo_tags: true} }

        it do
          expect(response).to have_http_status(:ok)
          expect(json).to match_array([hash_including('id' => photo2.id)])
        end
      end

      context 'when limit and only_with_geo_tags' do
        before { get :show, params: {id: rubric.id, only_with_geo_tags: true, offset: 1, limit: 5} }

        it do
          expect(response).to have_http_status(:ok)
          expect(json).to be_empty
        end
      end
    end
  end

  describe '#summary' do
    context 'when bounds' do
      let(:rubric) { create :rubric }
      let(:token) { create :'yandex/token' }

      before do
        create :photo, rubric: rubric, storage_filename: 'test.jpg', lat_long: [1, 2], yandex_token: token
        create :track, rubric: rubric, storage_filename: 'test.gpx', yandex_token: token

        get :summary, params: {id: rubric.id}
      end

      it { expect(json['bounds']).not_to be_empty }
    end

    context 'when without bounds' do
      before { get :summary, params: {id: 1} }

      it { expect(json['bounds']).to be_nil }
    end
  end
end
