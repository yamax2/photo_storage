# frozen_string_literal: true

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
      end
    end

    context 'when try to clear lat_long' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, :fake, storage_filename: 'test', yandex_token: token, name: 'my', lat_long: [1, 2] }

      before { put :update, params: {id: photo.id, photo: {lat_long: ['', '']}} }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).to be_valid
        expect(assigns(:photo).lat_long).to be_nil
        expect(response).to redirect_to(edit_admin_photo_path(photo))
      end
    end
  end
end
