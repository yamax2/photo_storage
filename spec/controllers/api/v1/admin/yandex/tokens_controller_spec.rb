# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Admin::Yandex::TokensController, type: :request do
  let(:json) { JSON.parse(response.body) }
  let!(:token) { create :'yandex/token', dir: '/test', other_dir: '/other', access_token: API_ACCESS_TOKEN }

  describe '#index' do
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

        get api_v1_admin_yandex_tokens_url
      end

      it do
        expect(response).to have_http_status(:ok)

        expect(json).to eq(
          [
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'photo'
            }
          ]
        )
      end
    end

    context 'when photos and tracks' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test'
        create :track, yandex_token: token, storage_filename: 'test'

        get api_v1_admin_yandex_tokens_url
      end

      let(:response_tokens) do
        [
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'photo'
          },
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'track'
          }
        ]
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(json).to match_array(response_tokens)
      end
    end

    context 'when multiple tokens' do
      let!(:another_token) { create :'yandex/token' }
      let(:response_tokens) do
        [
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'photo'
          },
          {
            'id' => token.id,
            'login' => token.login,
            'type' => 'track'
          },
          {
            'id' => another_token.id,
            'login' => another_token.login,
            'type' => 'photo'
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
  end

  describe '#show' do
    around do |example|
      Sidekiq::Testing.fake! { example.run }
    end

    after { Sidekiq::Worker.clear_all }

    context 'when wrong resource' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test.jpg', size: 12
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :wrong) }.
          to raise_error(Yandex::BackupInfoService::WrongResourceError)
      end
    end

    context 'when enqueue' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test.jpg', size: 12
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo) }.
          to change { Yandex::BackupInfoJob.jobs.size }.by(1)

        expect(response).to have_http_status(:accepted)
        expect(response.body).to be_empty
      end
    end

    context 'when job already enqueued' do
      before do
        RedisClassy.redis.set("backup_info:#{token.id}:photo", nil)

        create :photo, yandex_token: token, storage_filename: 'test.jpg', size: 12
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo) }.
          not_to(change { Yandex::BackupInfoJob.jobs.size })

        expect(response).to have_http_status(:accepted)
        expect(response.body).to be_empty
      end
    end

    context 'when job finished for photo' do
      before do
        RedisClassy.redis.set("backup_info:#{token.id}:photo", 'value')

        create :photo, yandex_token: token, storage_filename: 'test.jpg', size: 12
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo) }.
          not_to(change { Yandex::BackupInfoJob.jobs.size })

        expect(response).to have_http_status(:ok)

        expect(json['info']).to eq('value')
        expect(json['size']).to eq(12)
        expect(json['count']).to eq(1)
      end
    end

    context 'when job finished for track' do
      before do
        RedisClassy.redis.set("backup_info:#{token.id}:track", 'value')

        create :track, yandex_token: token, storage_filename: 'test.gpx', size: 12
      end

      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :track) }.
          not_to(change { Yandex::BackupInfoJob.jobs.size })

        expect(response).to have_http_status(:ok)

        expect(json['info']).to eq('value')
        expect(json['size']).to eq(12)
        expect(json['count']).to eq(1)
      end
    end

    context 'when wrong token' do
      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id * 2, resource: :photo) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when without resource param' do
      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id) }.
          to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when token without resources' do
      it do
        expect { get api_v1_admin_yandex_token_url(id: token.id, resource: :photo) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
