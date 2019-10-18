# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::Rubrics::PositionsController do
  render_views

  describe '#create' do
    let(:rubric) { create :rubric }

    context 'when bad request (without data param)' do
      subject { post :create, params: {positions: {id: rubric.id}} }

      it do
        expect(::Rubrics::ApplyOrderService).not_to receive(:call!)
        expect { subject }.to raise_error(ActionController::ParameterMissing).with_message(/data/)
      end
    end

    context 'when correct params' do
      subject { post :create, params: {id: rubric.id, data: '1,2,5'} }

      it do
        expect(::Rubrics::ApplyOrderService).to receive(:call!).with(data: [1, 2, 5], id: rubric.id)

        subject

        expect(response).to redirect_to(admin_rubrics_positions_path(id: rubric.id))
      end
    end

    context 'when wrong parent rubric' do
      subject { post :create, params: {id: rubric.id * 2, data: '1,2,5'} }

      it do
        expect(::Rubrics::ApplyOrderService).not_to receive(:call!)

        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when empty string as parent value' do
      subject { post :create, params: {id: '', data: '1,2,5'} }

      it do
        expect(::Rubrics::ApplyOrderService).to receive(:call!).with(data: [1, 2, 5], id: nil)

        subject

        expect(response).to redirect_to(admin_rubrics_positions_path)
      end
    end

    context 'when root' do
      subject { post :create, params: {data: '1,2,5'} }

      it do
        expect(::Rubrics::ApplyOrderService).to receive(:call!).with(data: [1, 2, 5], id: nil)

        subject

        expect(response).to redirect_to(admin_rubrics_positions_path)
      end
    end
  end

  describe '#index' do
    context 'rubric sorting' do
      let!(:rubric1) { create :rubric }
      let!(:rubric2) { create :rubric }

      let!(:photo) do
        create :photo, :fake, rubric: rubric1, exif: {}, original_timestamp: Date.yesterday, local_filename: 'test'
      end

      context 'when by first photo' do
        before { get :index, params: {ord: 'first_photo'} }

        it do
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubrics)).to eq([rubric1, rubric2])
          expect(response).to render_template(:index)
        end
      end

      context 'when default' do
        before { get :index }

        it do
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubrics)).to eq([rubric2, rubric1])
          expect(response).to render_template(:index)
        end
      end
    end

    context 'when root rubric' do
      context 'and without rubrics' do
        before { get :index }

        it do
          expect(response).to redirect_to(admin_rubrics_positions_path)
        end
      end

      context 'and one rubric exists' do
        let!(:rubric) { create :rubric }

        before { get :index }

        it do
          expect(response).to redirect_to(admin_rubrics_positions_path)
          expect(assigns(:rubric)).to be_nil
          expect(assigns(:rubrics)).to match_array([rubric])
        end
      end

      context 'and two rubrics exist' do
        let!(:rubric1) { create :rubric }
        let!(:rubric2) { create :rubric }

        before { get :index }

        it do
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubric)).to be_nil
          expect(assigns(:rubrics)).to eq([rubric2, rubric1])
          expect(response).to render_template(:index)
        end
      end
    end

    context 'when sub rubric' do
      let!(:rubric) { create :rubric }

      context 'and without rubrics' do
        before { get :index, params: {id: rubric.id} }

        it do
          expect(response).to redirect_to(admin_rubrics_positions_path)
          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:rubrics)).to be_empty
        end
      end

      context 'and one rubric exists' do
        let!(:rubric1) { create :rubric, rubric: rubric }

        before { get :index, params: {id: rubric.id} }

        it do
          expect(response).to redirect_to(admin_rubrics_positions_path)
          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:rubrics)).to match_array([rubric1])
        end
      end

      context 'and two rubrics exist' do
        let!(:rubric1) { create :rubric, rubric: rubric, ord: 1 }
        let!(:rubric2) { create :rubric, rubric: rubric, ord: 2 }

        before { get :index, params: {id: rubric.id} }

        it do
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:rubrics)).to eq([rubric1, rubric2])
          expect(response).to render_template(:index)
        end
      end
    end
  end
end
