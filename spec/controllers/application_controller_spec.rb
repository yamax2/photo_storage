# frozen_string_literal: true

RSpec.describe ApplicationController, type: :controller do
  render_views

  controller do
    def index
      render json: {}
    end
  end

  context 'when auth header' do
    before do
      request.headers['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('test:123')}"

      get :index
    end

    it do
      expect(controller.current_user).to have_attributes(user_name: 'test')
    end
  end

  context 'when without auth header' do
    before { get :index }

    it do
      expect(controller.current_user).to have_attributes(user_name: nil)
    end
  end
end
