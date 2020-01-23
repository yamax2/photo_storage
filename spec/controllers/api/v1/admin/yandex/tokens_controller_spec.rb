# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Admin::Yandex::TokensController do
  render_views

  let(:json) { JSON.parse(response.body) }
  let!(:token) { create :'yandex/token' }

  describe '#index' do
    context 'when without resources' do
      before { get :index }

      it do
        expect(response).to have_http_status(:ok)
        expect(json).to be_empty
      end
    end

    context 'when photos' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test'

        get :index
      end

      it do
        expect(response).to have_http_status(:ok)

        expect(json).to eq(
          [
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'photos'
            }
          ]
        )
      end
    end

    context 'when photos and tracks' do
      before do
        create :photo, yandex_token: token, storage_filename: 'test'
        create :track, yandex_token: token, storage_filename: 'test'

        get :index
      end

      it do
        expect(response).to have_http_status(:ok)

        expect(json).to match_array(
          [
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'photos'
            },
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'other'
            }
          ]
        )
      end
    end

    context 'when multiple tokens' do
      let!(:another_token) { create :'yandex/token' }

      before do
        create :photo, yandex_token: token, storage_filename: 'test'
        create :photo, yandex_token: another_token, storage_filename: 'test'

        create :track, yandex_token: token, storage_filename: 'test'

        get :index
      end

      it do
        expect(response).to have_http_status(:ok)

        expect(json).to match_array(
          [
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'photos'
            },
            {
              'id' => token.id,
              'login' => token.login,
              'type' => 'other'
            },
            {
              'id' => another_token.id,
              'login' => another_token.login,
              'type' => 'photos'
            }
          ]
        )
      end
    end
  end
end
