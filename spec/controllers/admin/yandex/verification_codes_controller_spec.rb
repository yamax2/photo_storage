# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::Yandex::VerificationCodesController do
  render_views

  describe '#show' do
    before do
      allow(::Yandex::CreateOrUpdateTokenJob).to receive(:perform_async)
    end

    context 'when code presents' do
      before { get :show, params: {code: '999'} }

      it do
        expect(::Yandex::CreateOrUpdateTokenJob).to have_received(:perform_async)
        expect(response).to redirect_to(admin_yandex_tokens_path)
        expect(flash[:notice]).to eq I18n.t('admin.yandex.token_performed')
      end
    end

    context 'when without code' do
      let(:request) { get :show, params: {code1: '999'} }

      it do
        expect { request }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end
end
