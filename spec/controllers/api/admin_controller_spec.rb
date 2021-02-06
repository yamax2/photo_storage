# frozen_string_literal: true

RSpec.describe Api::AdminController, type: :controller do
  render_views

  controller do
    def index
      render json: {result: :ok}
    end
  end

  let(:json) { JSON.parse(response.body) }

  context 'when user is not an admin' do
    before do
      request.headers['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('test:123')}"

      get :index
    end

    it do
      expect(response).to have_http_status(:forbidden)
      expect(json).to include('status' => 'forbidden')

      expect(controller.current_user).to have_attributes(user_name: 'test')
      expect(controller.current_user).not_to be_admin
    end
  end

  context 'when user is admin' do
    before do
      request.headers['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('admin:123')}"

      get :index
    end

    it do
      expect(response).to have_http_status(:ok)
      expect(json).to include('result' => 'ok')

      expect(controller.current_user).to have_attributes(user_name: 'admin')
      expect(controller.current_user).to be_admin
    end
  end

  context 'when without auth header' do
    before { get :index }

    it do
      expect(response).to have_http_status(:ok)
      expect(json).to include('result' => 'ok')

      expect(controller.current_user).to have_attributes(user_name: nil)
      expect(controller.current_user).to be_admin
    end
  end
end
