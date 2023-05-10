# frozen_string_literal: true

module Yandex
  class ReviseOtherDirJob
    include Sidekiq::Worker

    def perform(token_id, folder_index)
      token = Yandex::Token.find(token_id)
      service = ReviseOtherDirService.call!(token:, folder_index:)

      return if service.errors.blank?

      MailerJob.perform_async(
        'ReviseMailer',
        'failed',
        [token.other_dir, token_id, folder_index, service.errors]
      )
    end
  end
end
