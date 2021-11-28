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
      let(:token) { create :'yandex/token', other_dir: '/other' }

      let(:root_rubric) { create :rubric }
      let(:rubric) { create :rubric, rubric: root_rubric }
      let(:another_rubric) { create :rubric, rubric: root_rubric }

      let!(:photo1) do
        create :photo, rubric: root_rubric,
                       yandex_token: token,
                       storage_filename: 'test1',
                       width: 3_000,
                       height: 1_000,
                       rotated: 1
      end

      let!(:photo2) do
        create :photo,
               :video,
               rubric: root_rubric,
               yandex_token: token,
               storage_filename: 'test2.mp4',
               preview_filename: 'test2.jpg',
               width: 1_000,
               height: 2_000,
               lat_long: [1, 2]
      end

      let(:correct_response) do
        [
          {
            'id' => another_rubric.id,
            'model_type' => 'Rubric',
            'lat_long' => nil,
            'image_size' => [480, 360],
            'preview' => nil,
            'url' => "/rubrics/#{another_rubric.id}",
            'name' => "#{another_rubric.name}, фото: 1",
            'properties' => {
              'actual_image_size' => [480, 360],
              'css_transform' => nil,
              'turned' => false,
              'video' => false
            }
          },
          {
            'id' => rubric.id,
            'model_type' => 'Rubric',
            'lat_long' => nil,
            'image_size' => [300, 360],
            'preview' => "/proxy/yandex/previews/test_photos/test3?id=#{token.id}&size=300",
            'url' => "/rubrics/#{rubric.id}",
            'name' => "#{rubric.name}, фото: 1",
            'properties' => {
              'actual_image_size' => [300, 360],
              'css_transform' => nil,
              'turned' => false,
              'video' => false
            }
          },
          {
            'id' => photo1.id,
            'model_type' => 'Photo',
            'lat_long' => nil,
            'image_size' => [360, 120],
            'preview' => "/proxy/yandex/previews/test_photos/test1?id=#{token.id}&size=360",
            'url' => "/rubrics/#{root_rubric.id}/photos/#{photo1.id}",
            'name' => photo1.name,
            'properties' => {
              'actual_image_size' => [120, 360],
              'css_transform' => 'rotate(90deg)',
              'turned' => true,
              'video' => false
            }
          },
          {
            'id' => photo2.id,
            'model_type' => 'Photo',
            'lat_long' => {'x' => 1.0, 'y' => 2.0},
            'image_size' => [180, 360],
            'preview' => "/proxy/yandex/previews/other/test2.jpg?id=#{token.id}&size=180",
            'url' => "/rubrics/#{root_rubric.id}/photos/#{photo2.id}",
            'name' => photo2.name,
            'properties' => {
              'actual_image_size' => [180, 360],
              'css_transform' => nil,
              'turned' => false,
              'video' => true
            }
          }
        ]
      end

      before do
        photo = create :photo, rubric: rubric, yandex_token: token, storage_filename: 'test3', width: 500, height: 600

        rubric.update!(main_photo_id: photo.id)

        create :photo, rubric: another_rubric, yandex_token: token, storage_filename: 'test4', width: 600, height: 600

        root_rubric.update!(main_photo_id: photo1.id)
      end

      context 'and without pagination' do
        before { get api_v1_rubric_url(id: root_rubric.id) }

        it do
          expect(response).to have_http_status(:ok)

          expect(json).to eq(correct_response)
        end
      end

      context 'when pagination' do
        before { get api_v1_rubric_url(id: root_rubric.id, limit: 2, offset: 1) }

        it do
          expect(response).to have_http_status(:ok)

          expect(json).to eq(correct_response[1..2])
        end
      end

      context 'when desc_order' do
        before { get api_v1_rubric_url(id: root_rubric.id, desc_order: true) }

        it do
          expect(response).to have_http_status(:ok)

          expect(json.map { |x| [x['id'], x['model_type']] }).to eq(
            [
              [another_rubric.id, 'Rubric'],
              [rubric.id, 'Rubric'],
              [photo2.id, 'Photo'],
              [photo1.id, 'Photo']
            ]
          )
        end
      end

      context 'when pagination and desc_order' do
        before { get api_v1_rubric_url(id: root_rubric.id, limit: 2, offset: 1, desc_order: true) }

        it do
          expect(response).to have_http_status(:ok)

          expect(json.map { |x| [x['id'], x['model_type']] }).to eq(
            [
              [rubric.id, 'Rubric'],
              [photo2.id, 'Photo']
            ]
          )
        end
      end

      context 'when only_with_geo_tags' do
        before { get api_v1_rubric_url(id: root_rubric.id, only_with_geo_tags: true) }

        it do
          expect(response).to have_http_status(:ok)

          expect(json).to eq([correct_response.last])
        end
      end

      context 'when offset and only_with_geo_tags' do
        before { get api_v1_rubric_url(id: root_rubric.id, only_with_geo_tags: true, offset: 5) }

        it do
          expect(response).to have_http_status(:ok)
          expect(json).to be_empty
        end
      end
    end
  end

  describe '#index' do
    context 'when without rubrics' do
      before { get api_v1_rubrics_url }

      it do
        expect(response).to have_http_status(:ok)
        expect(json).to be_empty
      end
    end

    context 'when rubrics exist' do
      let(:token) { create :'yandex/token' }

      let!(:rubric1) { create :rubric }
      let!(:rubric2) { create :rubric, rubrics_count: 5 }

      let!(:photo1) do
        create :photo, rubric: rubric1, storage_filename: '1.jpg', yandex_token: token, width: 100, height: 100
      end

      before do
        create :photo, rubric: rubric2, storage_filename: '2.jpg', yandex_token: token, width: 100, height: 100

        rubric1.update!(main_photo_id: photo1.id)

        create :rubric
      end

      context 'when request without limits' do
        before { get api_v1_rubrics_url }

        it do
          expect(response).to have_http_status(:ok)

          expect(json).to eq(
            [
              {
                'id' => rubric2.id,
                'model_type' => 'Rubric',
                'lat_long' => nil,
                'image_size' => [480, 360],
                'preview' => nil,
                'url' => "/rubrics/#{rubric2.id}",
                'name' => "#{rubric2.name}, подрубрик: 5, фото: 1",
                'properties' => {
                  'actual_image_size' => [480, 360],
                  'css_transform' => nil,
                  'turned' => false,
                  'video' => false
                }
              },
              {
                'id' => rubric1.id,
                'model_type' => 'Rubric',
                'lat_long' => nil,
                'image_size' => [360, 360],
                'preview' => "/proxy/yandex/previews/test_photos/1.jpg?id=#{token.id}&size=360",
                'url' => "/rubrics/#{rubric1.id}",
                'name' => "#{rubric1.name}, фото: 1",
                'properties' => {
                  'actual_image_size' => [360, 360],
                  'css_transform' => nil,
                  'turned' => false,
                  'video' => false
                }
              }
            ]
          )
        end
      end

      context 'when limit and offset' do
        before { get api_v1_rubrics_url(limit: 50, offset: 1) }

        it do
          expect(response).to have_http_status(:ok)

          expect(json.map { |x| x['id'] }).to eq([rubric1.id])
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
