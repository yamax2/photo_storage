# frozen_string_literal: true

RSpec.describe Admin::DashboardController, type: :request do
  describe '#index' do
    context 'when default request' do
      before { get admin_root_url }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context 'when request with auth' do
      let(:request_proc) { ->(headers) { get admin_root_url, headers: } }

      it_behaves_like 'admin restricted route'
    end
  end
end
