# frozen_string_literal: true

RSpec.describe Admin::PhotosController, type: :request do
  describe '#edit' do
    context 'when wrong photo' do
      subject(:request!) { get edit_admin_photo_url(id: 1) }

      it do
        expect { request! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when unpublished photo' do
      subject(:request!) { get edit_admin_photo_url(id: photo.id) }

      let!(:photo) { create :photo, local_filename: 'test' }

      it do
        expect { request! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when published photo' do
      let(:token) { create :'yandex/token' }
      let(:photo) { create :photo, storage_filename: 'test', yandex_token: token }

      before { get edit_admin_photo_url(id: photo.id) }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end

    context 'when request with auth' do
      let(:token) { create :'yandex/token' }
      let(:photo) { create :photo, storage_filename: 'test', yandex_token: token }
      let(:request_proc) { ->(headers) { get edit_admin_photo_url(id: photo.id), headers: } }

      it_behaves_like 'admin restricted route'
    end
  end

  describe '#update' do
    context 'when wrong photo' do
      subject(:request!) { put admin_photo_url(id: 1, photo: {name: 'test'}) }

      it do
        expect { request! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when unpublished photo' do
      subject(:request!) { put admin_photo_url(id: photo.id, photo: {name: 'test'}) }

      let!(:photo) { create :photo, local_filename: 'test' }

      it do
        expect { request! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when without photo param' do
      subject(:request!) { put admin_photo_url(id: photo.id, photo1: {name: 'test'}) }

      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token }

      it do
        expect { request! }.to raise_error(ActionController::ParameterMissing)
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
      let(:timestamp) { Time.zone.local(2022, 9, 15, 21, 0, 28) }

      before do
        put admin_photo_url(id: photo.id, photo: {name: 'test', rotated: 1, original_timestamp: timestamp.to_fs})
      end

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).to be_valid
        expect(assigns(:photo)).to have_attributes(name: 'test', rotated: 1, original_timestamp: timestamp)

        expect(response).to redirect_to(edit_admin_photo_path(photo))
      end
    end

    context 'when new description' do
      let(:token) { create :'yandex/token' }
      let(:request) { put admin_photo_url(id: photo.id, get_new_description: true, photo: {name: 'test'}) }

      context 'when photo without lat_long' do
        let(:photo) { create :photo, storage_filename: 'test', yandex_token: token, name: 'my' }

        it do
          expect { request }.not_to(change { enqueued_jobs('descr', klass: Photos::LoadDescriptionJob) })

          expect(assigns(:photo)).to have_attributes(name: 'test')
        end
      end

      context 'when photo with lat_long' do
        let(:photo) { create :photo, storage_filename: 'test', yandex_token: token, description: nil, lat_long: [1, 2] }

        it do
          expect { request }.to change { enqueued_jobs('descr', klass: Photos::LoadDescriptionJob).size }.by(1)

          expect(assigns(:photo)).to have_attributes(name: 'test')
          expect(flash[:notice]).to eq I18n.t('admin.photos.edit.get_new_description_enqueued', name: 'test')
        end
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

    context 'when try to clear rotated attr' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token, rotated: 3 }

      before { put admin_photo_url(id: photo.id, photo: {rotated: ''}) }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).to be_valid
        expect(assigns(:photo).rotated).to be_nil

        expect(response).to redirect_to(edit_admin_photo_path(photo))
      end
    end

    context 'when assign effects' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token, effects: nil }

      before { put admin_photo_url(id: photo.id, photo: {effects: ['', 'scaleX(-1)', 'scaleY(-1)']}) }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).to be_valid
        expect(assigns(:photo).effects).to match_array(%w[scaleX(-1) scaleY(-1)])

        expect(response).to redirect_to(edit_admin_photo_path(photo))
      end
    end

    context 'when assign hide_on_map' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token }

      before { put admin_photo_url(id: photo.id, photo: {hide_on_map: '1'}) }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).to be_valid
        expect(assigns(:photo).hide_on_map).to be(true)
        expect(assigns(:photo).props).to include('hide_on_map' => true)

        expect(response).to redirect_to(edit_admin_photo_path(photo))
      end
    end

    context 'when clear hide_on_map attr' do
      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token, hide_on_map: true }

      before { put admin_photo_url(id: photo.id, photo: {hide_on_map: '0'}) }

      it do
        expect(assigns(:photo)).to eq(photo)
        expect(assigns(:photo)).to be_valid
        expect(assigns(:photo).hide_on_map).to be_nil
        expect(assigns(:photo).props).to be_empty

        expect(response).to redirect_to(edit_admin_photo_path(photo))
      end
    end

    context 'when request with auth' do
      let(:token) { create :'yandex/token' }
      let(:photo) { create :photo, storage_filename: 'test', yandex_token: token }
      let(:request_proc) { ->(headers) { put admin_photo_url(id: photo.id, photo: {name: 'test'}), headers: } }

      it_behaves_like 'admin restricted route'
    end
  end

  describe '#destroy' do
    context 'when wrong photo' do
      subject(:request!) { delete admin_photo_url(id: 1) }

      it do
        expect { request! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when unpublished photo' do
      subject(:request!) { delete admin_photo_url(id: photo.id) }

      let!(:photo) { create :photo, local_filename: 'test' }

      it do
        expect { request! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when successful delete' do
      subject(:request!) { delete admin_photo_url(id: photo.id) }

      let(:token) { create :'yandex/token' }
      let!(:photo) { create :photo, storage_filename: 'test', yandex_token: token }

      it do
        expect { request! }.to change(Photo, :count).by(-1)

        expect(response).to redirect_to(admin_root_path)
        expect(flash[:notice]).to eq I18n.t('admin.photos.destroy.success', name: photo.name)

        expect { photo.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when request with auth' do
      let(:token) { create :'yandex/token' }
      let(:photo) { create :photo, storage_filename: 'test', yandex_token: token }
      let(:request_proc) { ->(headers) { delete admin_photo_url(id: photo.id), headers: } }

      it_behaves_like 'admin restricted route'
    end
  end
end
