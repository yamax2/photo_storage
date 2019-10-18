# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Admin::Cart::RubricsController do
  render_views

  let!(:rubric1) { create :rubric, name: 'first' }
  let!(:rubric2) { create :rubric }
  let!(:sub_rubric1) { create :rubric, rubric: rubric1, name: 'sub 1' }
  let!(:sub_rubric2) { create :rubric, rubric: sub_rubric1 }
  let(:token) { create :'yandex/token' }

  let(:json) { JSON.parse(response.body) }

  describe '#index' do
    context 'when empty cart' do
      before { get :index }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(json).to be_empty
      end
    end

    context 'when some rubrics selected' do
      let!(:photo1) { create :photo, :fake, yandex_token: token, storage_filename: 'test', rubric: rubric1 }
      let!(:photo2) { create :photo, :fake, yandex_token: token, storage_filename: 'test', rubric: sub_rubric1 }

      let!(:photo3) { create :photo, :fake, yandex_token: token, storage_filename: 'test', rubric: rubric2 }
      let!(:photo4) { create :photo, :fake, yandex_token: token, storage_filename: 'test', rubric: rubric1 }
      let!(:photo5) { create :photo, :fake, yandex_token: token, storage_filename: 'test', rubric: sub_rubric2 }

      before do
        ::Cart::PhotoService.call!(photo: photo1)
        ::Cart::PhotoService.call!(photo: photo2)
      end

      context 'and first level' do
        before { get :index }

        it do
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)

          expect(json).to match_array([
            hash_including('id' => rubric1.id, 'text' => 'first [1]', 'children' => true)
          ])
        end
      end

      context 'and second level' do
        before { get :index, params: {id: rubric1.id} }

        it do
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)

          expect(json).to match_array([
            hash_including('id' => sub_rubric1.id, 'text' => 'sub 1 [1]', 'children' => false)
          ])
        end
      end
    end
  end
end
