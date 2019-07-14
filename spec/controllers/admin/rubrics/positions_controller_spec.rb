require 'rails_helper'

RSpec.describe Admin::Rubrics::PositionsController do
  render_views

  describe '#create' do
    before do
      allow(::Rubrics::ApplyOrder).to receive(:call!)
    end

    let(:rubric) { create :rubric }

    context 'when bad request (without positions)' do
      subject { post :create, params: {id: rubric.id} }

      it do
        expect { subject }.to raise_error(ActionController::ParameterMissing).with_message(/positions/)
        expect(::Rubrics::ApplyOrder).not_to have_received(:call!)
      end
    end

    context 'when bad request (without data param)' do
      subject { post :create, params: {positions: {id: rubric.id}} }

      it do
        expect { subject }.to raise_error(ActionController::ParameterMissing).with_message(/data/)
        expect(::Rubrics::ApplyOrder).not_to have_received(:call!)
      end
    end

    context 'when correct params' do
      before { post :create, params: {positions: {id: rubric.id, data: '1,2,5'}} }

      it do
        expect(::Rubrics::ApplyOrder).to have_received(:call!).with(data: [1, 2, 5], id: rubric.id.to_s)
        expect(response).to redirect_to(admin_rubrics_path)
      end
    end

    context 'when root' do
      before { post :create, params: {positions: {data: '1,2,5'}} }

      it do
        expect(::Rubrics::ApplyOrder).to have_received(:call!).with(data: [1, 2, 5], id: nil)
        expect(response).to redirect_to(admin_rubrics_path)
      end
    end
  end

  describe '#index' do
    context 'when root rubric' do
      context 'and without rubrics' do
        before { get :index }

        it do
          expect(response).to redirect_to(admin_rubrics_path)
        end
      end

      context 'and one rubric exists' do
        let!(:rubric) { create :rubric }

        before { get :index }

        it do
          expect(response).to redirect_to(admin_rubrics_path)
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
          expect(response).to redirect_to(admin_rubrics_path)
          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:rubrics)).to be_empty
        end
      end

      context 'and one rubric exists' do
        let!(:rubric1) { create :rubric, rubric: rubric }

        before { get :index, params: {id: rubric.id} }

        it do
          expect(response).to redirect_to(admin_rubrics_path)
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
