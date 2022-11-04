# frozen_string_literal: true

RSpec.describe Api::V1::Admin::Yandex::TokensController, type: :request do
  let(:json) { JSON.parse(response.body) }
  let!(:token) { create :'yandex/token', dir: '/test', other_dir: '/other', active: true }

  describe '#index' do
    context 'when without active tokens' do
      let!(:token) { create :'yandex/token' }

      before do
        create :track, yandex_token: token, storage_filename: 'test'

        get api_v1_admin_yandex_tokens_url
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(json).to be_empty
      end
    end

    context 'when without resources' do
      before { get api_v1_admin_yandex_tokens_url }

      it do
        expect(response).to have_http_status(:ok)
        expect(json).to be_empty
      end
    end

    context 'when photos' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test'
        create :photo, yandex_token: token, storage_filename: 'test1', folder_index: 1

        get api_v1_admin_yandex_tokens_url
      end

      it do
        expect(response).to have_http_status(:ok)

        expect(json).to eq(
          [
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'photo',
              'folder_index' => 0,
              'is_last' => false
            },
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'photo',
              'folder_index' => 1,
              'is_last' => true
            }
          ]
        )
      end
    end

    context 'when photos and videos' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test'
        create :photo, yandex_token: token, storage_filename: 'test', folder_index: 1
        create :photo, :video, yandex_token: token, storage_filename: 'test'

        get api_v1_admin_yandex_tokens_url
      end

      it do
        expect(response).to have_http_status(:ok)

        expect(json).to match_array(
          [
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'photo',
              'folder_index' => 0,
              'is_last' => false
            },
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'other',
              'folder_index' => 0,
              'is_last' => false
            },
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'photo',
              'folder_index' => 1,
              'is_last' => true
            }
          ]
        )
      end
    end

    context 'when photos and tracks' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test'
        create :track, yandex_token: token, storage_filename: 'test'
        create :track, yandex_token: token, storage_filename: 'test', folder_index: 1

        get api_v1_admin_yandex_tokens_url
      end

      let(:response_tokens) do
        [
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'other',
            'folder_index' => 0,
            'is_last' => false
          },
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'photo',
            'folder_index' => 0,
            'is_last' => false
          },
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'other',
            'folder_index' => 1,
            'is_last' => true
          }
        ]
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(json).to match_array(response_tokens)
      end
    end

    context 'when start indexes assigned' do
      let!(:token) do
        create :'yandex/token', dir: '/test',
                                other_dir: '/other',
                                active: true,
                                other_folder_archive_from: 1,
                                photos_folder_archive_from: 2
      end

      let(:response_tokens) do
        [
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'other',
            'folder_index' => 1,
            'is_last' => true
          }
        ]
      end

      before do
        create :photo, yandex_token: token, storage_filename: 'test'
        create :track, yandex_token: token, storage_filename: 'test'
        create :track, yandex_token: token, storage_filename: 'test', folder_index: 1

        get api_v1_admin_yandex_tokens_url
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(json).to match_array(response_tokens)
      end
    end

    context 'when multiple tokens' do
      let!(:another_token) { create :'yandex/token', dir: '/test', other_dir: '/other', active: true }
      let(:response_tokens) do
        [
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'photo',
            'folder_index' => 0,
            'is_last' => false
          },
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'other',
            'folder_index' => 0,
            'is_last' => true
          },
          {
            'id' => another_token.id,
            'login' => another_token.login,
            'type' => 'photo',
            'folder_index' => 0,
            'is_last' => true
          }
        ]
      end

      before do
        create :photo, yandex_token: token, storage_filename: 'test'
        create :photo, yandex_token: another_token, storage_filename: 'test'

        create :track, yandex_token: token, storage_filename: 'test'

        get api_v1_admin_yandex_tokens_url
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(json).to match_array(response_tokens)
      end
    end

    context 'when with auth' do
      let(:request_proc) { ->(headers) { get api_v1_admin_yandex_tokens_url, headers: } }

      it_behaves_like 'admin restricted route', api: true
    end
  end

  describe '#show' do
    context 'when wrong resource' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test.jpg', size: 12
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :wrong, folder_index: 0) }.
          to raise_error(Yandex::BackupInfoService::WrongResourceError)
      end
    end

    context 'when enqueue' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test.jpg', size: 12
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo, folder_index: 0) }.
          to change { enqueued_jobs('tokens', klass: Yandex::BackupInfoJob).size }.by(1)

        expect(response).to have_http_status(:accepted)
        expect(response.body).to be_empty
      end
    end

    context 'when job already enqueued' do
      before do
        RedisClassy.redis.set("backup_info:#{token.id}:photo:0", nil)

        create :photo, yandex_token: token, storage_filename: 'test.jpg', size: 12
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo, folder_index: 0) }.
          not_to(change { enqueued_jobs('tokens').size })

        expect(response).to have_http_status(:accepted)
        expect(response.body).to be_empty
      end
    end

    context 'when job finished for photo' do
      before do
        RedisClassy.redis.set("backup_info:#{token.id}:photo:0", 'value')

        create :photo, yandex_token: token, storage_filename: 'test.jpg', size: 12
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo, folder_index: 0) }.
          not_to(change { enqueued_jobs('tokens').size })

        expect(response).to have_http_status(:ok)

        expect(json['info']).to eq('value')
        expect(json['size']).to eq(12)
        expect(json['count']).to eq(1)
        expect(json['folder_index']).to eq(0)
      end
    end

    context 'when job finished for other' do
      before do
        RedisClassy.redis.set("backup_info:#{token.id}:other:1", 'value')

        create :track, yandex_token: token, storage_filename: 'test.gpx', size: 12, folder_index: 1
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :other, folder_index: 1) }.
          not_to(change { enqueued_jobs('tokens').size })

        expect(response).to have_http_status(:ok)

        expect(json['info']).to eq('value')
        expect(json['size']).to eq(12)
        expect(json['count']).to eq(1)
        expect(json['folder_index']).to eq(1)
      end
    end

    context 'when wrong token' do
      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id * 2, resource: :photo, folder_index: 0) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when without folder_index' do
      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo) }.
          to raise_error(ActionController::ParameterMissing, /folder_index/)
      end
    end

    context 'when without resource param' do
      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, folder_index: 0) }.
          to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when token without resources' do
      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo, folder_index: 0) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when with auth' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test.jpg', size: 12
      end

      let(:request_proc) do
        ->(headers) { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo, folder_index: 0), headers: }
      end

      it_behaves_like 'admin restricted route', api: true
    end
  end

  describe '#touch' do
    before { Timecop.freeze(current_time) }

    after { Timecop.return }

    let(:current_time) { Time.zone.local(2017, 1, 1, 15, 45, 55) }
    let(:request) { get touch_api_v1_admin_yandex_token_url(token.id) }

    context 'when successful update' do
      it do
        expect { request }.to change { token.reload.last_archived_at }.from(nil).to(current_time)

        expect(response).to have_http_status(:accepted)
        expect(json).to include('id' => token.id, 'last_archived_at' => String)
      end
    end

    context 'when wrong id' do
      let(:request) { get touch_api_v1_admin_yandex_token_url(token.id * 2) }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when validation failed' do
      before do
        Yandex::Token.where(id: token.id).update_all(active: true, other_dir: nil)
      end

      it do
        expect { request }.not_to(change { token.reload.last_archived_at })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to be_empty
      end
    end

    context 'when with auth' do
      let(:request_proc) { ->(headers) { get touch_api_v1_admin_yandex_token_url(token.id), headers: } }

      it_behaves_like 'admin restricted route', api: true
    end
  end
end
