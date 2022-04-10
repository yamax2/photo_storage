# frozen_string_literal: true

module Yandex
  class CreateOrUpdateTokenJob
    include Sidekiq::Worker
    sidekiq_options queue: :tokens

    def perform(code)
      CreateOrUpdateTokenService.call!(code:)
    end
  end
end
