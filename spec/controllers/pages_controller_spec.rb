# frozen_string_literal: true

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
      context 'and without photos and rubrics' do
        before do
          create :photo, :fake, local_filename: 'test', rubric: rubric
          get :show, params: {id: rubric.id}
        end

        it do
          expect(response).to redirect_to(root_path)
          expect(assigns(:page)).to be_a(Page)
          expect(assigns(:page).rubric).to eq(rubric)
        end
      end

      context 'and with published photos' do
        let(:token) { create :'yandex/token' }

        before do
          create :photo, :fake, storage_filename: 'test', rubric: rubric, yandex_token: token, width: 100, height: 100

          get :show, params: {id: rubric.id}
        end

        it do
          expect(response).to have_http_status(:ok)
          expect(assigns(:page)).to be_a(Page)
          expect(assigns(:page).rubric).to eq(rubric)
        end
      end

      context 'and with sub rubric without published photo' do
        before do
          create :rubric, rubric: rubric

          get :show, params: {id: rubric.id}
        end

        it do
          expect(response).to redirect_to(root_path)
        end
      end

      context 'and with sub rubric with published photo' do
        let(:sub_rubric) { create :rubric, rubric: rubric }
        let(:token) { create :'yandex/token' }

        before do
          create :photo, :fake, storage_filename: 'test', rubric: rubric, yandex_token: token, width: 100, height: 100

          get :show, params: {id: rubric.id}
        end

        it do
          expect(response).to have_http_status(:ok)
          expect(assigns(:page)).to be_a(Page)
          expect(assigns(:page).rubric).to eq(rubric)
        end
      end
    end
  end
end
