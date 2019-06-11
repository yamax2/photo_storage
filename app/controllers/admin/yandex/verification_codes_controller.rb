module Admin
  module Yandex
    # https://oauth.yandex.ru/verification_code
    class VerificationCodesController < AdminController
      def show
        ::Yandex::CreateOrUpdateTokenJob.perform_async(params.require(:code))

        flash[:notice] = I18n.t('admin.yandex.token_performed')

        redirect_to controller: 'admin/yandex/tokens', action: :index
      end
    end
  end
end
