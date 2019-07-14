module Yandex
  class RefreshTokensJob
    include Sidekiq::Worker

    def perform
      Token.order(:id).select(:id).each_row(with_lock: true) do |row|
        RefreshTokenJob.perform_async(row[:token_id].to_i)
      end
    end
  end
end
