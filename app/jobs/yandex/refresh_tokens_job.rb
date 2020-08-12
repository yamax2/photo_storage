# frozen_string_literal: true

module Yandex
  class RefreshTokensJob
    include Sidekiq::Worker
    sidekiq_options queue: :tokens

    def perform
      Token.order(:id).select(:id).each_row(with_hold: true, symbolize_keys: true) do |row|
        RefreshTokenJob.perform_async(row[:id].to_i)
      end
    end
  end
end
