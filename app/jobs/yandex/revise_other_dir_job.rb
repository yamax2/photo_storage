# frozen_string_literal: true

module Yandex
  class ReviseOtherDirJob
    include Sidekiq::Worker

    def perform(token_id)
      token = Yandex::Token.find(token_id)
      service = ReviseOtherDirService.call!(token:)

      ReviseMailer.delay.failed(token.other_dir, token_id, service.errors) if service.errors.present?
    end
  end
end
