# frozen_string_literal: true

RSpec.describe Admin::Reports::ActivitiesController, type: :request do
  describe '#index' do
    let(:request_proc) { ->(headers) { get admin_reports_activities_url, headers: } }

    it_behaves_like 'admin restricted route'
  end
end
