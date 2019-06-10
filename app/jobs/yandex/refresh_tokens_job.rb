module Yandex
  class RefreshTokensJob
    include Sidekiq::Worker

    def perform
      # amount of tokens is small
      Token.order(:id).pluck(:id).each do |token_id|
        RefreshTokenJob.perform_async(token_id)
      end
    end
  end
end
