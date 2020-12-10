# frozen_string_literal: true

RSpec.describe Admin::DashboardController, type: :request do
  describe '#index' do
    before { get admin_root_url }

    it do
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end
end
