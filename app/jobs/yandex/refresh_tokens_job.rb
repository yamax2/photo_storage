module Yandex
  class RefreshTokensJob
    include Sidekiq::Worker

    def perform
      Token.order(:id).select(:id).each_row(with_lock: true, symbolize_keys: true) do |row|
        RefreshTokenJob.perform_async(row[:id].to_i)
      end
    end
  end
end
