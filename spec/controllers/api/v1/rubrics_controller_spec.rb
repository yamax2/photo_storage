# frozen_string_literal: true

RSpec.describe Api::V1::RubricsController, type: :request do
  let(:json) { JSON.parse(response.body) }

  describe '#show' do
    context 'when wrong rubric' do
      before { get api_v1_rubric_url(id: 1, offset: 1, limit: 5) }

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
        create :photo, rubric: rubric,
                       yandex_token: token,
                       storage_filename: 'test',
                       width: 3_000,
                       height: 1_000,
                       rotated: 1
      end

      let!(:photo2) do
        create :photo, rubric: rubric,
                       yandex_token: token,
                       storage_filename: 'test',
                       width: 1_000,
                       height: 2_000,
                       lat_long: [1, 2]
      end

      context 'and with limit' do
        before { get api_v1_rubric_url(id: rubric.id, offset: 1, limit: 1) }

        it do
          expect(response).to have_http_status(:ok)
          expect(json).to match_array(
            [
              hash_including(
                'url',
                'image_size',
                'preview',
                'id' => photo2.id,
                'properties' => hash_including(
                  'actual_image_size' => [180, 360],
                  'turned' => false,
                  'css_transform' => nil
                )
              )
            ]
          )
        end
      end

      context 'when without limits' do
        before { get api_v1_rubric_url(id: rubric.id) }

        it do
          expect(response).to have_http_status(:ok)

          expect(json).to match_array(
            [
              hash_including(
                'id' => photo1.id,
                'image_size' => [360, 120],
                'properties' => hash_including(
                  'turned' => true,
                  'actual_image_size' => [120, 360],
                  'css_transform' => 'rotate(90deg)'
                )
              ),

              hash_including(
                'id' => photo2.id,
                'image_size' => [180, 360],
                'properties' => hash_including(
                  'turned' => false,
                  'actual_image_size' => [180, 360],
                  'css_transform' => nil
                )
              )
            ]
          )
        end
      end

      context 'when only_with_geo_tags' do
        before { get api_v1_rubric_url(id: rubric.id, only_with_geo_tags: true) }

        it do
          expect(response).to have_http_status(:ok)
          expect(json).to match_array([hash_including('id' => photo2.id)])
        end
      end

      context 'when limit and only_with_geo_tags' do
        before { get api_v1_rubric_url(id: rubric.id, only_with_geo_tags: true, offset: 1, limit: 5) }

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

        get summary_api_v1_rubric_url(id: rubric.id)
      end

      it { expect(json['bounds']).not_to be_empty }
    end

    context 'when without bounds' do
      before { get summary_api_v1_rubric_url(id: 1) }

      it { expect(json['bounds']).to be_nil }
    end
  end
end
