# frozen_string_literal: true

module Yandex
  class ReviseDirJob
    include Sidekiq::Worker

    def perform(dir, token_id)
      token = Yandex::Token.find(token_id)
      service = ReviseDirService.call!(dir: dir, token: token)

      ReviseMailer.delay.failed(dir, token_id, service.errors) if service.errors.present?
    end
  end
end
