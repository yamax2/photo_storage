# frozen_string_literal: true

module Yandex
  # FIXME: remove after proxy rework
  class TokenChangedNotifyJob
    include Sidekiq::Worker
    sidekiq_options queue: :tokens

    delegate :config, to: YandexClient, private: true

    def perform
      response = HTTP.
        timeout(
          connect: config.connect_timeout,
          read: config.read_timeout,
          write: config.write_timeout
        ).
        get(Rails.application.routes.url_helpers.proxy_reload_url)

      raise 'proxy reload error' unless response.status.success?
    end
  end
end
