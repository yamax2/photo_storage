# frozen_string_literal: true

RSpec.describe Api::V1::TracksController, type: :request do
  describe '#index' do
    let(:json) { JSON.parse(response.body) }

    context 'when wrong rubric' do
      it do
        expect { get api_v1_rubric_tracks_url(rubric_id: 1) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when rubric without tracks' do
      let(:rubric) { create :rubric }

      before { get api_v1_rubric_tracks_url(rubric_id: rubric.id) }

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:rubric)).to eq(rubric)

        expect(json).to be_empty
      end
    end

    context 'when some tracks in rubric' do
      let(:rubric) { create :rubric }

      let(:token) { create :'yandex/token', other_dir: '/other' }

      let!(:track2) do
        create :track, storage_filename: 'test2.gpx',
                       rubric:,
                       yandex_token: token,
                       duration: 2.hours + 59.minutes,
                       distance: 200,
                       name: 'track2',
                       original_filename: 'track2.gpx',
                       started_at: 1.day.ago,
                       color: 'red'
      end

      let!(:track3) do
        create :track, storage_filename: 'test3.gpx',
                       rubric:,
                       yandex_token: token,
                       duration: 50.minutes,
                       distance: 30,
                       name: 'track3',
                       original_filename: 'track3.gpx',
                       started_at: 10.days.ago,
                       color: 'blue'
      end

      let(:actual_response) do
        [
          {
            'id' => track3.id,
            'name' => 'track3: 30.0 км, 50мин., ср. скорость 36.0 км/ч',
            'url' => "/proxy/yandex/other/test3.gpx?fn=track3.gpx&id=#{token.id}",
            'color' => 'blue'
          },
          {
            'id' => track2.id,
            'name' => 'track2: 200.0 км, 2ч. 59мин., ср. скорость 67.04 км/ч',
            'url' => "/proxy/yandex/other/test2.gpx?fn=track2.gpx&id=#{token.id}",
            'color' => 'red'
          }
        ]
      end

      before do
        create :track, local_filename: 'test', rubric: rubric # track1
        create :track, storage_filename: 'test3.gpx', yandex_token: token # track4

        get api_v1_rubric_tracks_url(rubric_id: rubric.id)
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:rubric)).to eq(rubric)
        expect(assigns(:tracks)).to eq([track3, track2])

        expect(json).to eq(actual_response)
      end
    end
  end
end
