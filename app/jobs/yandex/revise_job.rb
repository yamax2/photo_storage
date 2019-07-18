module Yandex
  class ReviseJob
    include Sidekiq::Worker

    def perform
      ActiveRecord::Base.each_row_by_sql(
        query,
        with_hold: true,
        symbolize_keys: true,
        block_size: 10
      ) do |row|
        ReviseDirJob.perform_async(row[:dir], row[:token_id])
      end
    end

    private

    def query
      <<~SQL
        SELECT yandex_token_id token_id,
               regexp_replace(storage_filename, '[a-z0-9]+\.[A-z]+', '') dir
        FROM photos
          WHERE storage_filename IS NOT NULL
            GROUP by 1,2
              ORDER BY MAX(created_at)
      SQL
    end
  end
end
