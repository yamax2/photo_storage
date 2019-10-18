# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::RubricsController do
  render_views

  describe '#create' do
    context 'when valid' do
      context 'and without parent rubric' do
        before do
          post :create, params: {rubric: {name: 'test', description: 'text'}}
        end

        it do
          expect(assigns(:rubric)).to have_attributes(name: 'test', description: 'text', rubric_id: nil)
          expect(response).to redirect_to(admin_rubrics_path)
        end
      end

      context 'and with parent rubric' do
        let!(:parent_rubric) { create :rubric }

        before do
          post :create, params: {rubric: {name: 'test', description: 'text', rubric_id: parent_rubric.id}}
        end

        it do
          expect(assigns(:rubric)).to have_attributes(name: 'test', description: 'text', rubric_id: parent_rubric.id)
          expect(response).to redirect_to(admin_rubrics_path(id: parent_rubric.id))
        end
      end
    end

    context 'when invalid' do
      before do
        post :create, params: {rubric: {name: '', description: 'text'}}
      end

      it do
        expect(assigns(:rubric)).not_to be_valid
        expect(response).to render_template(:new)
      end
    end

    context 'when without required params' do
      let(:request) do
        post :create, params: {rubric1: {name: 'zozo', description: 'text'}}
      end

      it do
        expect { request }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe '#destroy' do
    let!(:parent_rubric) { create :rubric }
    let!(:rubric) { create :rubric, rubric: parent_rubric }

    context 'when single destroy' do
      before { delete :destroy, params: {id: rubric.id} }

      it do
        expect(response).to redirect_to(admin_rubrics_path(id: parent_rubric.id))
        expect(assigns(:rubric)).not_to be_persisted
        expect(flash[:notice]).to eq I18n.t('admin.rubrics.destroy.success', name: rubric.name)

        expect { rubric.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when rubric with sub_rubrics' do
      before { delete :destroy, params: {id: parent_rubric.id} }

      it do
        expect(response).to redirect_to(admin_rubrics_path)
        expect(assigns(:rubric)).not_to be_persisted
        expect(flash[:notice]).to eq I18n.t('admin.rubrics.destroy.success', name: parent_rubric.name)

        expect { rubric.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { parent_rubric.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#index' do
    let!(:rubrics) { create_list :rubric, 30, rubric_id: nil }
    let(:main_rubric) { rubrics.first }
    let!(:sub_rubrics) { create_list :rubric, 2, rubric_id: main_rubric.id }

    context 'when root rubrics' do
      context 'when first page' do
        before { get :index }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubrics).size).to eq(25)
        end
      end

      context 'when second page' do
        before { get :index, params: {page: 2} }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubrics).size).to eq(5)
        end
      end

      context 'when wrong page' do
        before { get :index, params: {page: 3} }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubrics)).to be_empty
        end
      end
    end

    context 'when sub_rubrics' do
      before { get :index, params: {id: main_rubric.id} }

      it do
        expect(response).to render_template(:index)
        expect(response).to have_http_status(:ok)
        expect(assigns(:rubrics)).to match_array(sub_rubrics)
      end
    end

    context 'when wrong parent rubric_id' do
      let(:request) { get :index, params: {id: 0} }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#new' do
    context 'when without parent rubric_id' do
      before { get :new }

      it do
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:ok)
        expect(assigns(:rubric).rubric_id).to be_nil
      end
    end

    context 'when parent rubric_id presents' do
      let!(:parent_rubric) { create :rubric }

      before { get :new, params: {id: parent_rubric.id} }

      it do
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:ok)
        expect(assigns(:rubric).rubric).to eq(parent_rubric)
      end
    end

    context 'when wrong parent rubric_id' do
      let(:request) { get :new, params: {id: 1} }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#update' do
    let!(:rubric) { create :rubric }

    context 'when without parent rubric_id' do
      before { post :update, params: {id: rubric.id, rubric: {name: 'text 1', description: 'zozo'}} }

      it do
        expect(response).to redirect_to(admin_rubrics_path)
        expect(assigns(:rubric)).to eq(rubric)
        expect(assigns(:rubric)).to have_attributes(name: 'text 1', description: 'zozo', rubric_id: nil)
      end
    end

    context 'when with parent rubric_id' do
      let!(:parent_rubric) { create :rubric }

      before do
        post :update, params: {
          id: rubric.id,
          rubric: {name: 'text 1', description: 'zozo', rubric_id: parent_rubric.id}
        }
      end

      it do
        expect(response).to redirect_to(admin_rubrics_path(id: parent_rubric.id))
        expect(assigns(:rubric)).to eq(rubric)
        expect(assigns(:rubric)).to have_attributes(name: 'text 1', description: 'zozo', rubric_id: parent_rubric.id)
      end
    end

    context 'when record invalid' do
      before { post :update, params: {id: rubric.id, rubric: {name: ''}} }

      it do
        expect(response).to render_template(:edit)
        expect(assigns(:rubric)).to eq(rubric)
        expect(assigns(:rubric)).not_to be_valid
      end
    end

    context 'when without required params' do
      let(:request) { post :update, params: {id: rubric.id, rubric1: {name: 'zozo'}} }

      it do
        expect { request }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when wrong rubric id' do
      let(:request) { post :update, params: {id: 0, rubric: {name: 'zozo'}} }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#warm_up' do
    let!(:rubric) { create :rubric }

    before do
      allow(::Rubrics::WarmUpJob).to receive(:perform_async)
    end

    context 'when without photo size' do
      let(:request) { get :warm_up, params: {id: rubric.id} }

      it do
        expect { request }.to raise_error(ActionController::ParameterMissing)
        expect(::Rubrics::WarmUpJob).not_to have_received(:perform_async)
      end
    end

    context 'when successful call' do
      before { get :warm_up, params: {id: rubric.id, size: 'preview'} }

      it do
        expect(response).to redirect_to(admin_rubrics_path)
        expect(::Rubrics::WarmUpJob).to have_received(:perform_async)
      end
    end

    context 'when wrong rubric' do
      let(:request) { get :warm_up, params: {id: -1} }

      it do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
