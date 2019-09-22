require 'rails_helper'

RSpec.describe Admin::PhotosController do
  render_views

  describe '#edit' do
    context 'when wrong photo' do
      subject { get :edit, params: {id: 1} }

      it do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when unpublished photo' do
      let!(:photo) { create :photo, :fake, local_filename: 'test' }

      subject { get :edit, params: {id: photo.id} }

      it do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when published photo' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, :fake, storage_filename: 'test', yandex_token: token }

      before { get :edit, params: {id: photo.id} }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    before { allow(::Photos::MainPhotoService).to receive(:call!) }

    context 'when wrong photo' do
      subject { put :update, params: {id: 1, photo: {name: 'test'}} }

      it do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when unpublished photo' do
      let!(:photo) { create :photo, :fake, local_filename: 'test' }

      subject { put :update, params: {id: photo.id, photo: {name: 'test'}} }

      it do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when without photo param' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, :fake, storage_filename: 'test', yandex_token: token }

      subject { put :update, params: {id: photo.id, photo1: {name: 'test'}} }

      it do
        expect { subject }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when update with errors' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, :fake, storage_filename: 'test', yandex_token: token }

      before { put :update, params: {id: photo.id, photo: {name: ''}} }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).not_to be_valid
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
        expect(::Photos::MainPhotoService).not_to have_received(:call!)
      end
    end

    context 'when successful update' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, :fake, storage_filename: 'test', yandex_token: token, name: 'my' }

      before { put :update, params: {id: photo.id, photo: {name: 'test'}} }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).to be_valid
        expect(assigns(:photo).name).to eq('test')
        expect(response).to redirect_to(edit_admin_photo_path(photo))
        expect(::Photos::MainPhotoService).to have_received(:call!)
      end
    end
  end
end