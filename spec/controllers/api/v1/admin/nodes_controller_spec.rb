# frozen_string_literal: true

RSpec.describe Api::V1::Admin::NodesController, type: :request do
  before do
    allow(Rails.application.credentials).to receive(:backup_secret).and_return('very_secret')
  end

  describe '#show' do
    let(:node) { create :'yandex/token' }

    context 'when with auth' do
      let(:request_proc) { ->(headers) { get api_v1_admin_node_url(node.id), headers: } }

      it_behaves_like 'admin restricted route', api: true
    end

    context 'when wrong node id' do
      it do
        expect { get api_v1_admin_node_url(node.id * 2) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'correct request' do
      let(:decoded_secret) do
        decryptor = OpenSSL::Cipher.new('aes-256-cbc').decrypt.tap do |cipher|
          cipher.key = Digest::SHA256.digest(Rails.application.credentials.backup_secret)
          cipher.iv = Digest::MD5.digest(node.login)
        end

        decryptor.update(
          Base64.decode64(response.parsed_body.fetch('secret'))
        ) + decryptor.final
      end

      before { get api_v1_admin_node_url(node.id) }

      it do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)

        expect(response.parsed_body).
          to include('id' => node.id, 'type' => 'yandex', 'name' => node.login, 'secret' => String)
        expect(decoded_secret).to eq(node.access_token)
      end
    end
  end
end
