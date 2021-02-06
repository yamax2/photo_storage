# frozen_string_literal: true

RSpec.shared_examples 'admin restricted route' do |api: false|
  # let(:request_proc)  { -> (headers) { get :index, headers: headers } }
  context 'when with non-admin user' do
    before do
      request_proc.call('HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('test:123')}")
    end

    it do
      expect(response).to have_http_status(:forbidden)

      if api
        expect(JSON.parse(response.body)).to include('status' => 'forbidden')
      else
        expect(response.body).to be_empty
      end
    end
  end

  context 'when admin user' do
    before do
      request_proc.call('HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('admin:123')}")
    end

    it { expect(response).not_to have_http_status(:forbidden) }
  end
end
