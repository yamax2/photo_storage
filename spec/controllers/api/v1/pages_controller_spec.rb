# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::PagesController do
  render_views

  describe '#show' do
    context 'when without offset' do
      subject { get :show, params: {id: 1, limit: 5} }

      it do
        expect { subject }.to raise_error(ActionController::ParameterMissing, /offset/)
      end
    end

    context 'when without limit' do
      subject { get :show, params: {id: 1, offset: 5} }

      it do
        expect { subject }.to raise_error(ActionController::ParameterMissing, /limit/)
      end
    end

    context 'when wrong rubric' do
      subject { get :show, params: {id: 1, offset: 1, limit: 5} }

      it do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when correct rubric' do
      let(:root_rubric) { create :rubric }
      let(:rubric) { create :rubric, rubric: root_rubric }

      before { get :show, params: {id: rubric.id, offset: 1, limit: 5} }

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:page).rubric).to eq(rubric)
        expect(assigns(:page).rubric.association(:rubric)).not_to be_loaded
        expect(JSON.parse(response.body)).to be_empty
      end
    end
  end
end
