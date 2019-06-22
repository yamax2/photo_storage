require 'rails_helper'

RSpec.describe PagesController do
  render_views

  describe '#show' do
    let!(:rubric) { create :rubric }

    context 'when root' do
      before { get :show }

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:page)).to be_a(Page)
        expect(assigns(:page).rubric).to be_nil
      end
    end

    context 'when rubric' do
      before { get :show, params: {id: rubric.id} }

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:page)).to be_a(Page)
        expect(assigns(:page).rubric).to eq(rubric)
      end
    end
  end
end
