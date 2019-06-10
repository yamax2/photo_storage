module Yandex
  class CreateOrUpdateTokenJob
    include Sidekiq::Worker

    def perform(code)
      CreateOrUpdateTokenService.call!(code: code)
    end
  end
end
