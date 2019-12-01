# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Admin::RubricsController do
  render_views

  describe '#index' do
    let!(:rubric2) { create :rubric, name: 'rubric 2' }
    let!(:rubric1) { create :rubric, name: 'rubric 1' }
    let!(:rubric3) { create :rubric, rubric: rubric1, name: 'sub rubric' }

    let(:json) { JSON.parse(response.body) }

    context 'when without id param' do
      before { get :index }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(assigns(:rubrics)).to match_array([rubric1, rubric2])

        expect(json).to match_array([
          hash_including('text', 'id' => rubric2.id, 'children' => false),
          hash_including('text', 'id' => rubric1.id, 'children' => true)
        ])
      end
    end

    context 'when with id param' do
      before { get :index, params: {id: rubric1.id} }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(assigns(:rubrics)).to match_array([rubric3])
      end
    end

    context 'when with str param' do
      before { get :index, params: {str: 'sub'} }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(assigns(:rubrics)).to match_array([rubric1])
      end
    end

    context 'when with str and id params' do
      before { get :index, params: {str: 'sub', id: rubric1.id} }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(assigns(:rubrics)).to match_array([rubric3])
      end
    end
  end

  describe '#update' do
    let(:json) { JSON.parse(response.body) }

    context 'when wrong id value' do
      it do
        expect { post :update, params: {id: 1} }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when wrong photo id' do
      let!(:rubric) { create :rubric }

      it do
        expect { post :update, params: {id: rubric.id, rubric: {main_photo_id: 1}} }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when without photo id' do
      let!(:rubric) { create :rubric }

      it do
        expect { post :update, params: {id: rubric.id, rubric: {main_photo_zozo: 1}} }.
          to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when correct params' do
      let(:rubric) { create :rubric }
      let!(:photo) { create :photo, local_filename: 'test', rubric: rubric }

      it do
        expect { post :update, params: {id: rubric.id, rubric: {main_photo_id: photo.id}} }.
          to change { rubric.reload.main_photo }.from(nil).to(photo)

        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(rubric.id)
      end
    end
  end
end
