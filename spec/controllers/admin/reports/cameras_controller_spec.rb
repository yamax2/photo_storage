# frozen_string_literal: true

RSpec.describe Admin::Reports::CamerasController, type: :request do
  describe '#index' do
    let(:request_proc) { ->(headers) { get admin_reports_cameras_url, headers: } }

    it_behaves_like 'admin restricted route'
  end
end
