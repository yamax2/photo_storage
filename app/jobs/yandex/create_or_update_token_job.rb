module Yandex
  class CreateOrUpdateTokenJob
    include Sidekiq::Worker
    sidekiq_options queue: :maintance

    def perform(code)
      CreateOrUpdateTokenService.call!(code: code)
    end
  end
end
