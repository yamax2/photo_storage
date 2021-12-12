# frozen_string_literal: true

RSpec.describe Api::V1::Admin::VideosController, type: :request do
  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  before do
    allow(Rails.application.credentials).to receive(:backup_secret).and_return('very_secret')
  end

  describe '#create' do
    subject(:request) { post api_v1_admin_videos_url(video: correct_video_attrs) }

    let(:rubric) { create :rubric }
    let(:token_active) { true }
    let!(:token) { create :'yandex/token', active: token_active }

    let(:correct_video_attrs) do
      {
        name: 'test',
        original_filename: 'test.mp4',
        original_timestamp: '2021-11-04T07:12:43+05:00',
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
        height: 768,
        tz: 'Europe/Moscow'
      }
    end

    context 'when correct params' do
      let(:video) { Photo.videos.first! }
      let(:upload_job_args) { enqueued_jobs(klass: Videos::UploadInfoJob).map { |j| j['args'] } }

      it do
        expect { request }.
          to change { enqueued_jobs('descr', klass: Photos::LoadDescriptionJob).size }.by(1).
          and change { enqueued_jobs(klass: Videos::UploadInfoJob).size }.by(1).
          and change { enqueued_jobs(klass: Videos::MoveOriginalJob).size }.by(0)

        expect(response).to have_http_status(:created)
        expect(json[:id]).to eq(video.id)

        expect(video).to have_attributes(
          correct_video_attrs.merge(
            yandex_token_id: token.id,
            preview_filename: String,
            storage_filename: String,
            lat_long: ActiveRecord::Point.new(10.5, 11.65),
            original_timestamp: Time.zone.local(2021, 11, 4, 7, 12, 43)
          )
        )

        expect(upload_job_args).to match_array([[video.id, "video_upload:#{video.id}", false]])
      end
    end

    context 'when corrent params with a preloaded file' do
      subject(:request) do
        post api_v1_admin_videos_url(video: correct_video_attrs, temporary_uploaded_filename: 'test.mp4')
      end

      let(:video) { Photo.videos.first! }
      let(:move_job_args) { enqueued_jobs(klass: Videos::MoveOriginalJob).map { |j| j['args'] } }
      let(:upload_job_args) { enqueued_jobs(klass: Videos::UploadInfoJob).map { |j| j['args'] } }

      it do
        expect { request }.
          to change { enqueued_jobs('descr', klass: Photos::LoadDescriptionJob).size }.by(1).
          and change { enqueued_jobs(klass: Videos::MoveOriginalJob).size }.by(1).
          and change { enqueued_jobs(klass: Videos::UploadInfoJob).size }.by(1)

        expect(response).to have_http_status(:created)
        expect(json[:id]).to eq(video.id)

        expect(move_job_args).to match_array([[video.id, 'test.mp4']])
        expect(upload_job_args).to match_array([[video.id, "video_upload:#{video.id}", true]])
      end
    end

    context 'when error on enqueue move job' do
      subject(:request) do
        post api_v1_admin_videos_url(video: correct_video_attrs, temporary_uploaded_filename: 'test.mp4')
      end

      before do
        allow(Videos::MoveOriginalJob).to receive(:perform_async).and_raise('boom!')
      end

      it do
        expect { request }.
          to raise_error('boom!').
          and change(Photo, :count).by(0).
          and change { enqueued_jobs('descr', klass: Photos::LoadDescriptionJob).size }.by(0).
          and change { enqueued_jobs(klass: Videos::UploadInfoJob).size }.by(0).
          and change { enqueued_jobs(klass: Videos::MoveOriginalJob).size }.by(0)
      end
    end

    context 'when without active tokens' do
      let(:token_active) { false }

      it do
        expect { request }.
          to change { enqueued_jobs('descr', klass: Photos::LoadDescriptionJob).size }.by(0).
          and change { enqueued_jobs(klass: Videos::UploadInfoJob).size }.by(0).
          and change { enqueued_jobs(klass: Videos::MoveOriginalJob).size }.by(0)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to include(:yandex_token)
      end
    end

    context 'when wrong content_type' do
      subject(:request) { post api_v1_admin_videos_url(video: attrs) }

      let(:attrs) do
        correct_video_attrs.
          merge(content_type: 'image/jpg').
          except(:preview_filename, :preview_size, :preview_md5)
      end

      it do
        expect { request }.
          to change { enqueued_jobs('descr', klass: Photos::LoadDescriptionJob).size }.by(0).
          and change { enqueued_jobs(klass: Videos::UploadInfoJob).size }.by(0).
          and change { enqueued_jobs(klass: Videos::MoveOriginalJob).size }.by(0)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json[:content_type]).to eq('not a video')
      end
    end

    context 'when incorrect params' do
      subject(:request) { post api_v1_admin_videos_url(video: correct_video_attrs.merge(name: '    ')) }

      it do
        expect { request }.
          to change { enqueued_jobs('descr', klass: Photos::LoadDescriptionJob).size }.by(0).
          and change { enqueued_jobs(klass: Videos::UploadInfoJob).size }.by(0).
          and change { enqueued_jobs(klass: Videos::MoveOriginalJob).size }.by(0)

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

  describe '#show' do
    let(:node) { create :'yandex/token' }

    context 'when video does not exist' do
      it do
        expect { get api_v1_admin_video_url(1) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when wrong content_type' do
      let(:video) { create :photo, yandex_token: node, storage_filename: 'test1.jpg' }

      it do
        expect { get api_v1_admin_video_url(video) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when info has expired processing' do
      let(:video) { create :photo, :video, yandex_token: node, storage_filename: 'test1.mp4' }

      it do
        expect { get api_v1_admin_video_url(video) }.not_to raise_error

        expect(response).to have_http_status(:gone)
        expect(json).to be_empty
      end
    end

    context 'when info exists' do
      let(:video) { create :photo, :video, yandex_token: node, storage_filename: 'test1.mp4' }

      before do
        RedisClassy.set("video_upload:#{video.id}", 'Test info')
      end

      it do
        expect { get api_v1_admin_video_url(video) }.not_to raise_error

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('Test info')

        expect(response.headers.fetch('Content-Type')).to include('text/plain')
      end
    end

    context 'when with auth' do
      let(:video) { create :photo, :video, storage_filename: 'test.mp4', yandex_token: node }

      let(:request_proc) do
        ->(headers) { get api_v1_admin_video_url(video), headers: headers }
      end

      it_behaves_like 'admin restricted route', api: true
    end
  end
end
