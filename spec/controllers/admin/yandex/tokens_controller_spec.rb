# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::Yandex::TokensController do
  render_views

  describe '#index' do
    let!(:tokens) { create_list :'yandex/token', 30 }

    context 'when first page' do
      before { get :index }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)

        expect(assigns(:tokens).size).to eq(25)
        expect(assigns(:new_token_url)).to include(API_APPLICATION_KEY)
      end
    end

    context 'when second page' do
      before { get :index, params: {page: 2} }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)

        expect(assigns(:tokens).size).to eq(5)
        expect(assigns(:new_token_url)).to include(API_APPLICATION_KEY)
      end
    end

    context 'when wrong page' do
      before { get :index, params: {page: 3} }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)

        expect(assigns(:tokens)).to be_empty
        expect(assigns(:new_token_url)).to include(API_APPLICATION_KEY)
      end
    end

    context 'when without tokens' do
      let!(:tokens) { nil }

      before { get :index }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)

        expect(assigns(:tokens)).to be_empty
        expect(assigns(:new_token_url)).to include(API_APPLICATION_KEY)
      end
    end
  end

  describe '#refresh' do
    before do
      allow(::Yandex::RefreshTokenJob).to receive(:perform_async)
    end

    context 'when token exists' do
      let!(:token) { create :'yandex/token' }

      before { get :refresh, params: {id: token.id} }

      it do
        expect(assigns(:token)).to eq(token)
        expect(::Yandex::RefreshTokenJob).to have_received(:perform_async).with(token.id)
        expect(response).to redirect_to(admin_yandex_tokens_path)
        expect(flash[:notice]).to eq I18n.t('admin.yandex.tokens.refresh.success', login: token.login)
      end
    end

    context 'when wrong token' do
      let(:request) { get :refresh, params: {id: 1} }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#destroy' do
    context 'when token exists' do
      let!(:token) { create :'yandex/token' }

      before { delete :destroy, params: {id: token.id} }

      it do
        expect(assigns(:token)).to eq(token)
        expect(assigns(:token)).not_to be_persisted
        expect(response).to redirect_to(admin_yandex_tokens_path)
        expect(flash[:notice]).to eq I18n.t('admin.yandex.tokens.destroy.success', login: token.login)
      end
    end

    context 'when wrong token' do
      let(:request) { delete :destroy, params: {id: 1} }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#update' do
    context 'when successful update' do
      let!(:token) { create :'yandex/token' }

      before do
        post :update, params: {id: token.id, yandex_token: {dir: '/my_dir', other_dir: '/other_dir', active: true}}
      end

      it do
        expect(assigns(:token)).to eq(token)
        expect(assigns(:token)).to have_attributes(active: true, dir: '/my_dir', other_dir: '/other_dir')
        expect(response).to redirect_to(admin_yandex_tokens_path)
      end
    end

    context 'when errors' do
      let!(:token) { create :'yandex/token' }

      before do
        post :update, params: {id: token.id, yandex_token: {dir: '', other_dir: '', active: true}}
      end

      it do
        expect(assigns(:token)).to eq(token)
        expect(assigns(:token)).not_to be_valid
        expect(response).to render_template(:edit)
      end
    end

    context 'when wrong params' do
      let!(:token) { create :'yandex/token' }

      let(:request) do
        post :update, params: {id: token.id, yandex_token1: {dir: '', other_dir: '', active: true}}
      end

      it do
        expect { request }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when wrong token' do
      let(:request) { post :update, params: {id: 1} }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
