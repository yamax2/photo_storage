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
end
