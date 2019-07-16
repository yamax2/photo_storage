require 'rails_helper'

RSpec.describe Admin::DashboardController do
  render_views

  describe '#index' do
    before { get :index }

    it do
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end
end
