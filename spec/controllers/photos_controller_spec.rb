# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhotosController do
  render_views

  describe '#show' do
    let(:rubric) { create :rubric }
    let(:token) { create :'yandex/token' }
    let(:photo) do
      create :photo, :fake, storage_filename: 'test', yandex_token: token, rubric: rubric, width: 4_096, height: 3_072
    end

    context 'when preview selected' do
      before { get :show, params: {page_id: rubric.id, id: photo.id} }

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:page).rubric).to eq(rubric)
        expect(assigns(:photos).current).to eq(photo)
        expect(response.body).to match(/proxy.+1066/)
      end
    end

    context 'when large preview selected' do
      before do
        cookies[:preview_id] = 'max'
        get :show, params: {page_id: rubric.id, id: photo.id}
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:page).rubric).to eq(rubric)
        expect(assigns(:photos).current).to eq(photo)
        expect(response.body).to match(/proxy.+1280/)
      end
    end

    context 'when wrong rubric in params' do
      before { get :show, params: {page_id: rubric.id * 2, id: photo.id} }

      it do
        expect(response).to redirect_to(page_photo_path(rubric.id, photo.id))
      end
    end

    context 'when non-existent photo' do
      subject { get :show, params: {page_id: rubric.id, id: photo.id * 2} }

      it do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
