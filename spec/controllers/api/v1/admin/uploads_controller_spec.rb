# frozen_string_literal: true

RSpec.describe Api::V1::Admin::UploadsController do
  render_views

  describe '#create' do
    context 'when without content param' do
      subject(:upload!) { post :create, params: {rubric_id: 1}, xhr: true }

      it do
        expect { upload! }.to raise_error(ActionController::ParameterMissing).with_message(/content/)
      end
    end

    context 'when wrong mime type' do
      let(:rubric) { create :rubric }
      let(:content) { fixture_file_upload('spec/fixtures/test.txt', 'text/plain') }

      before { post :create, params: {rubric_id: rubric.id, content:}, xhr: true }

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to be_empty
      end
    end

    context 'when try to upload video' do
      let(:rubric) { create :rubric }
      let(:content) { fixture_file_upload('spec/fixtures/test.txt', 'video/mp4') }

      before { post :create, params: {rubric_id: rubric.id, content:}, xhr: true }

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to be_empty
      end
    end

    context 'when with auth' do
      let(:rubric) { create :rubric }
      let(:content) { fixture_file_upload('spec/fixtures/test.txt', 'text/plain') }
      let(:request_proc) do
        lambda do |headers|
          request.headers.merge!(headers)
          post :create, params: {rubric_id: rubric.id, content:}, xhr: true
        end
      end

      it_behaves_like 'admin restricted route', api: true
    end

    shared_examples 'content upload' do |test_file, test_type, klass|
      let(:content) { fixture_file_upload(test_file, test_type) }

      context 'when wrong rubric' do
        it do
          expect { post :create, params: {rubric_id: 1, content:}, xhr: true }.
            to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when without rubric_id param' do
        subject(:upload!) { post :create, params: {content:}, xhr: true }

        it do
          expect { upload! }.to raise_error(ActionController::ParameterMissing).with_message(/rubric_id/)
        end
      end

      context 'when successful upload' do
        let(:rubric) { create :rubric }

        after do
          klass.all.each { |photo| FileUtils.rm_f(photo.tmp_local_filename) }
        end

        context 'when without external info' do
          before { post :create, params: {rubric_id: rubric.id, content:}, xhr: true }

          it do
            expect(response).to have_http_status(:ok)
            expect(response.parsed_body).to include('id')
          end
        end

        context 'when with external info' do
          before { post :create, params: {rubric_id: rubric.id, content:, external_info: 'test'}, xhr: true }

          it do
            expect(response).to have_http_status(:ok)
            expect(response.parsed_body.keys).to match_array(%w[id])

            expect(response.parsed_body['id']).to eq(assigns(:model).id)
            expect(assigns(:model).external_info).to eq('test')
          end
        end
      end

      context 'when error on save' do
        let(:rubric) { create :rubric }
        let(:local_file) { Rails.root.join('tmp/files', assigns[:model].local_filename) }

        before do
          allow_any_instance_of(klass).to receive(:valid?).and_return(false) # rubocop:disable RSpec/AnyInstance
          post :create, params: {rubric_id: rubric.id, content:}, xhr: true
        end

        after { FileUtils.rm_f(local_file) }

        it do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(File.exist?(local_file)).to be(false)
          expect(response.parsed_body).to be_empty
        end
      end
    end

    it_behaves_like 'content upload', 'spec/fixtures/test2.jpg', 'image/jpeg', Photo
    it_behaves_like 'content upload', 'spec/fixtures/test1.gpx', 'application/gpx+xml', Track
  end
end
