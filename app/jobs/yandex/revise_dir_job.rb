# frozen_string_literal: true

module Yandex
  class ReviseDirJob
    include Sidekiq::Worker

    def perform(dir, token_id, folder_index)
      token = Yandex::Token.find(token_id)
      service = ReviseDirService.call!(dir:, token:, folder_index:)

      ReviseMailer.delay.failed(dir, token_id, folder_index, service.errors) if service.errors.present?
    end
  end
end
