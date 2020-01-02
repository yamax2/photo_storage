# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::TracksController do
  render_views

  describe '#index' do
    let(:json) { JSON.parse(response.body) }

    context 'when wrong rubric' do
      it do
        expect { get :index, params: {page_id: 1} }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when rubric without tracks' do
      let(:rubric) { create :rubric }

      before { get :index, params: {page_id: rubric.id} }

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:rubric)).to eq(rubric)
        expect(json).to be_empty
      end
    end

    context 'when some tracks in rubric' do
      let(:rubric) { create :rubric }
      let!(:track1) { create :track, local_filename: 'test', rubric: rubric }

      let(:token) { create :'yandex/token', other_dir: '/other' }

      let!(:track2) do
        create :track, storage_filename: 'test2.gpx',
                       rubric: rubric,
                       yandex_token: token,
                       avg_speed: 2,
                       duration: 20,
                       distance: 200,
                       name: 'track2',
                       original_filename: 'track2.gpx'
      end

      let!(:track3) do
        create :track, storage_filename: 'test3.gpx',
                       rubric: rubric,
                       yandex_token: token,
                       avg_speed: 3,
                       duration: 30,
                       distance: 300,
                       name: 'track3',
                       original_filename: 'track3.gpx'
      end

      let!(:track4) { create :track, storage_filename: 'test3.gpx', yandex_token: token }

      before do
        request.cookies['proxy_session'] = 'session'

        get :index, params: {page_id: rubric.id}
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:rubric)).to eq(rubric)
        expect(assigns(:tracks)).to eq([track3, track2])

        expect(json).to eq(
          [
            {
              'id' => track3.id,
              'name' => 'track3',
              'avg_speed' => '3.0',
              'distance' => '300.0',
              'duration' => '0.01',
              'url' => 'http://proxy.photostorage.localhost/originals/other/test3.gpx' \
                       "?fn=track3.gpx&id=#{token.id}&session=session"
            },
            {
              'id' => track2.id,
              'name' => 'track2',
              'avg_speed' => '2.0',
              'distance' => '200.0',
              'duration' => '0.01',
              'url' => 'http://proxy.photostorage.localhost/originals/other/test2.gpx?fn=track2.gpx' \
                       "&id=#{token.id}&session=session"
            }
          ]
        )
      end
    end
  end
end
