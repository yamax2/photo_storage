# frozen_string_literal: true

RSpec.describe Api::V1::Admin::VideosController, type: :request do
  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  before do
    allow(Rails.application.credentials).to receive(:backup_secret).and_return('very_secret')
  end

  describe '#create' do
    let(:rubric) { create :rubric }
    let(:token_active) { true }
    let!(:token) { create :'yandex/token', active: token_active }

    let(:correct_video_attrs) do
      {
        name: 'test',
        original_filename: 'test.mp4',
        storage_filename: 'test.mp4',
        preview_filename: 'test.mp4.jpg',
        preview_size: 100,
        size: 2_000,
        preview_md5: Digest::MD5.hexdigest('preview'),
        preview_sha256: Digest::SHA256.hexdigest('preview'),
        md5: Digest::MD5.hexdigest('test'),
        sha256: Digest::SHA256.hexdigest('test'),
        content_type: 'video/mp4',
        rubric_id: rubric.id,
        lat_long: [10.5, 11.65],
        exif: {'make' => 'Sony', 'model' => 'Test'},
        width: 1_024,
        height: 768
      }
    end

    context 'when correct params' do
      let(:video) { Photo.videos.first! }

      before { post api_v1_admin_videos_url(video: correct_video_attrs) }

      it do
        expect(response).to have_http_status(:ok)
        expect(json[:id]).to eq(video.id)
        expect(json[:upload_info]).to be_a(String)
        expect(video).to have_attributes(
          correct_video_attrs.merge(
            yandex_token_id: token.id,
            preview_filename: String,
            storage_filename: String,
            lat_long: ActiveRecord::Point.new(10.5, 11.65)
          )
        )
      end
    end

    context 'when without active tokens' do
      let(:token_active) { false }

      before { post api_v1_admin_videos_url(video: correct_video_attrs) }

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to include(:yandex_token)
      end
    end

    context 'when wrong content_type' do
      let(:attrs) do
        correct_video_attrs.
          merge(content_type: 'image/jpg').
          except(:preview_filename, :preview_size, :preview_md5)
      end

      before { post api_v1_admin_videos_url(video: attrs) }

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json[:content_type]).to eq('not a video')
      end
    end

    context 'when incorrect params' do
      before { post api_v1_admin_videos_url(video: correct_video_attrs.merge(name: '    ')) }

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to include(:name)
      end
    end

    context 'when with auth' do
      let(:request_proc) do
        ->(headers) { post api_v1_admin_videos_url(video: {original_filename: 'test'}), headers: headers }
      end

      it_behaves_like 'admin restricted route', api: true
    end
  end
end
