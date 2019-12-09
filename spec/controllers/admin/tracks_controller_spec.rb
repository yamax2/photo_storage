# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::TracksController do
  render_views

  describe '#destroy' do
    context 'when wrong rubric' do
      let(:track) { create :track, local_filename: 'test' }

      it do
        expect { delete :destroy, params: {rubric_id: track.rubric_id * 2, id: track.id} }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when wrong id' do
      let(:rubric) { create :rubric }

      it do
        expect { delete :destroy, params: {rubric_id: rubric.id, id: 1} }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when correct params' do
      let(:track) { create :track, local_filename: 'test' }

      before { delete :destroy, params: {rubric_id: track.rubric_id, id: track.id} }

      it do
        expect(response).to redirect_to(admin_rubric_tracks_path(track.rubric))
        expect(assigns(:track)).not_to be_persisted
        expect(flash[:notice]).to eq I18n.t('admin.tracks.destroy.success', name: track.name)

        expect { track.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#edit' do
    context 'when correct id' do
      let(:track) { create :track, local_filename: 'test' }

      before { get :edit, params: {rubric_id: track.rubric_id, id: track.id} }

      it do
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:ok)
        expect(assigns(:track)).to eq(track)
      end
    end

    context 'when wrong id' do
      let(:rubric) { create :rubric }

      it do
        expect { get :edit, params: {rubric_id: rubric.id, id: 1} }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when wrong rubric' do
      let(:track) { create :track, local_filename: 'test' }

      it do
        expect { get :edit, params: {rubric_id: track.rubric_id * 2, id: track.id} }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#index' do
    context 'when wrong rubric_id' do
      it do
        expect { get :index, params: {rubric_id: 2} }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when correct rubric' do
      let(:rubric) { create :rubric }
      let!(:tracks) { create_list :track, 30, rubric: rubric, local_filename: 'test' }

      context 'and first page' do
        before { get :index, params: {rubric_id: rubric.id} }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:tracks).size).to eq(25)
        end
      end

      context 'when second page' do
        before { get :index, params: {rubric_id: rubric.id, page: 2} }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:tracks).size).to eq(5)
        end
      end

      context 'when wrong page' do
        before { get :index, params: {rubric_id: rubric.id, page: 5} }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:tracks)).to be_empty
        end
      end

      context 'when filter' do
        let!(:my_track) { create :track, name: 'zozo', rubric: rubric, local_filename: 'test' }

        before { get :index, params: {rubric_id: rubric.id, q: {name_cont: 'zo'}} }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:tracks)).to match_array([my_track])
        end
      end
    end
  end

  describe '#update' do
    context 'when wrong rubric_id' do
      let(:track) { create :track, local_filename: 'test' }

      it do
        expect { post :update, params: {rubric_id: track.rubric_id * 2, id: track.id, track: {name: 'test'}} }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when wrong id' do
      let(:rubric) { create :rubric }

      it do
        expect { post :update, params: {rubric_id: rubric.id, id: 1, track: {name: 'test'}} }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when record invalid' do
      let(:track) { create :track, local_filename: 'test', name: 'test' }

      before { post :update, params: {rubric_id: track.rubric_id, id: track.id, track: {name: ''}} }

      it do
        expect(response).to render_template(:edit)
        expect(assigns(:track)).to eq(track)
        expect(assigns(:track)).not_to be_valid
      end
    end

    context 'when without required params' do
      let(:track) { create :track, local_filename: 'test', name: 'zozo' }

      it do
        expect { post :update, params: {rubric_id: track.rubric_id, id: track.id, track1: {name: 'test'}} }.
          to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when successful update' do
      let(:track) { create :track, local_filename: 'test', name: 'test' }

      before { post :update, params: {rubric_id: track.rubric_id, id: track.id, track: {name: 'zozo'}} }

      it do
        expect(response).to redirect_to(admin_rubric_tracks_path(track.rubric))
        expect(assigns(:track)).to eq(track)
        expect(assigns(:track)).to have_attributes(name: 'zozo')
      end
    end
  end
end
