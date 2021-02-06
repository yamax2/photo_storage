# frozen_string_literal: true

RSpec.describe Admin::Rubrics::PositionsController, type: :request do
  describe '#create' do
    let(:rubric) { create :rubric }

    context 'when bad request (without data param)' do
      subject(:request) { post admin_rubrics_positions_url(positions: {id: rubric.id}) }

      it do
        expect(::Rubrics::ApplyOrderService).not_to receive(:call!)
        expect { request }.to raise_error(ActionController::ParameterMissing).with_message(/data/)
      end
    end

    context 'when correct params' do
      it do
        expect(::Rubrics::ApplyOrderService).to receive(:call!).with(data: [1, 2, 5], id: rubric.id)

        post admin_rubrics_positions_url(id: rubric.id, data: '1,2,5')

        expect(response).to redirect_to(admin_rubrics_positions_path(id: rubric.id))
      end
    end

    context 'when wrong parent rubric' do
      subject(:request) { post admin_rubrics_positions_url(id: rubric.id * 2, data: '1,2,5') }

      it do
        expect(::Rubrics::ApplyOrderService).not_to receive(:call!)

        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when empty string as parent value' do
      it do
        expect(::Rubrics::ApplyOrderService).to receive(:call!).with(data: [1, 2, 5], id: nil)

        post admin_rubrics_positions_url(id: '', data: '1,2,5')

        expect(response).to redirect_to(admin_rubrics_positions_path)
      end
    end

    context 'when root' do
      it do
        expect(::Rubrics::ApplyOrderService).to receive(:call!).with(data: [1, 2, 5], id: nil)

        post admin_rubrics_positions_url(data: '1,2,5')

        expect(response).to redirect_to(admin_rubrics_positions_path)
      end
    end

    context 'when with auth' do
      let(:request_proc) { ->(headers) { post admin_rubrics_positions_url(data: '1,2,5'), headers: headers } }

      it_behaves_like 'admin restricted route'
    end
  end

  describe '#index' do
    context 'rubric sorting' do
      let!(:rubric1) { create :rubric }
      let!(:rubric2) { create :rubric }

      before { create :photo, rubric: rubric1, exif: {}, original_timestamp: Date.yesterday, local_filename: 'test' }

      context 'when by first photo' do
        before { get admin_rubrics_positions_url(ord: 'first_photo') }

        it do
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubrics)).to eq([rubric1, rubric2])
          expect(response).to render_template(:index)
        end
      end

      context 'when default' do
        before { get admin_rubrics_positions_url }

        it do
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubrics)).to eq([rubric2, rubric1])
          expect(response).to render_template(:index)
        end
      end
    end

    context 'when root rubric' do
      context 'and without rubrics' do
        before { get admin_rubrics_positions_url }

        it do
          expect(response).to redirect_to(admin_rubrics_path)
        end
      end

      context 'and one rubric exists' do
        let!(:rubric) { create :rubric }

        before { get admin_rubrics_positions_url }

        it do
          expect(response).to redirect_to(admin_rubrics_path)
          expect(assigns(:rubric)).to be_nil
          expect(assigns(:rubrics)).to match_array([rubric])
        end
      end

      context 'and two rubrics exist' do
        let!(:rubric1) { create :rubric }
        let!(:rubric2) { create :rubric }

        before { get admin_rubrics_positions_url }

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
        before { get admin_rubrics_positions_url(id: rubric.id) }

        it do
          expect(response).to redirect_to(admin_rubrics_path(rubric.id))
          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:rubrics)).to be_empty
        end
      end

      context 'and one rubric exists' do
        let!(:rubric1) { create :rubric, rubric: rubric }

        before { get admin_rubrics_positions_url(id: rubric.id) }

        it do
          expect(response).to redirect_to(admin_rubrics_path(rubric.id))
          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:rubrics)).to match_array([rubric1])
        end
      end

      context 'and two rubrics exist' do
        let!(:rubric1) { create :rubric, rubric: rubric, ord: 1 }
        let!(:rubric2) { create :rubric, rubric: rubric, ord: 2 }

        before { get admin_rubrics_positions_url(id: rubric.id) }

        it do
          expect(response).to have_http_status(:ok)
          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:rubrics)).to eq([rubric1, rubric2])
          expect(response).to render_template(:index)
        end
      end
    end

    context 'when with auth' do
      let(:request_proc) { ->(headers) { get admin_rubrics_positions_url, headers: headers } }

      it_behaves_like 'admin restricted route'
    end
  end
end
