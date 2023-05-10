# frozen_string_literal: true

module Yandex
  class ReviseDirJob
    include Sidekiq::Worker

    def perform(dir, token_id, folder_index)
      token = Yandex::Token.find(token_id)
      service = ReviseDirService.call!(dir:, token:, folder_index:)

      return if service.errors.blank?

      MailerJob.perform_async(
        'ReviseMailer',
        'failed',
        [dir, token_id, folder_index, service.errors]
      )
    end
  end
end
