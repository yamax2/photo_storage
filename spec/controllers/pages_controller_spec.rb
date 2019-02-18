require 'rails_helper'

RSpec.describe PagesController do
  render_views

  describe '#index' do
    before { get :index }

    it do
      expect(response).to have_http_status(:ok)
    end
  end
end
