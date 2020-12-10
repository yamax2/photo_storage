# frozen_string_literal: true

RSpec.describe Admin::PhotosController, type: :request do
  describe '#edit' do
    context 'when wrong photo' do
      subject(:request) { get edit_admin_photo_url(id: 1) }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when unpublished photo' do
      subject(:request) { get edit_admin_photo_url(id: photo.id) }

      let!(:photo) { create :photo, local_filename: 'test' }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when published photo' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token }

      before { get edit_admin_photo_url(id: photo.id) }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    context 'when wrong photo' do
      subject(:request) { put admin_photo_url(id: 1, photo: {name: 'test'}) }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when unpublished photo' do
      subject(:request) { put admin_photo_url(id: photo.id, photo: {name: 'test'}) }

      let!(:photo) { create :photo, local_filename: 'test' }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when without photo param' do
      subject(:request) { put admin_photo_url(id: photo.id, photo1: {name: 'test'}) }

      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token }

      it do
        expect { request }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when update with errors' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token }

      before { put admin_photo_url(id: photo.id, photo: {name: ''}) }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).not_to be_valid
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end

    context 'when successful update' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token, name: 'my' }

      before { put admin_photo_url(id: photo.id, photo: {name: 'test'}) }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).to be_valid
        expect(assigns(:photo).name).to eq('test')
        expect(response).to redirect_to(edit_admin_photo_path(photo))
      end
    end

    context 'when try to clear lat_long' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token, name: 'my', lat_long: [1, 2] }

      before { put admin_photo_url(id: photo.id, photo: {lat_long: ['', '']}) }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).to be_valid
        expect(assigns(:photo).lat_long).to be_nil
        expect(response).to redirect_to(edit_admin_photo_path(photo))
      end
    end
  end
end
