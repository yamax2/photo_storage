# frozen_string_literal: true

RSpec.describe Api::V1::Admin::ReportsController, type: :request do
  describe '#show' do
    context 'when with auth' do
      let(:request_proc) { ->(headers) { get api_v1_admin_report_url(id: :cameras), headers: } }

      it_behaves_like 'admin restricted route', api: true
    end

    context 'when without any data' do
      before { get api_v1_admin_report_url(id: :cameras) }

      it do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to be_empty
      end
    end

    context 'when some data' do
      before do
        create_list :photo, 2, exif: {make: 'some', model: '1'}, local_filename: '1.jpg'

        get api_v1_admin_report_url(id: :cameras)
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to contain_exactly({'camera' => 'SOME 1', 'count' => 2})
      end
    end
  end
end
