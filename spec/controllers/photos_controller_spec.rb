require 'rails_helper'

RSpec.describe PhotosController do
  render_views

  describe '#show' do
    let(:rubric) { create :rubric }
    let(:token) { create :'yandex/token' }
    let(:photo) do
      create :photo, :fake, storage_filename: 'test', yandex_token: token, rubric: rubric, width: 1_000, height: 1_000
    end

    before { get :show, params: {page_id: rubric.id, id: photo.id} }

    it do
      expect(response).to have_http_status(:ok)
      expect(assigns(:page).rubric).to eq(rubric)
      expect(assigns(:photos).current).to eq(photo)
    end
  end
end
