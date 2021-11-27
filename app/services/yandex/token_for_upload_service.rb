# frozen_string_literal: true

module Yandex
  class TokenForUploadService
    include ::Interactor

    CACHE_REDIS_KEY = 'yandex_tokens_usage'
    FIND_SCRIPT = File.read('./app/services/yandex/find_script.lua')
    private_constant :FIND_SCRIPT

    delegate :resource_size, :token_id, to: :context

    def call
      return if actual_tokens.empty?

      token_id = RedisScript.
        new(FIND_SCRIPT).
        exec(
          keys: CACHE_REDIS_KEY,
          argv: [actual_tokens.to_json, resource_size]
        )

      context.token_id = token_id.to_i if token_id
    end

    private

    def actual_tokens
      return @actual_tokens if defined?(@actual_tokens)

      table = Token.arel_table
      free_space = Arel::Nodes::Subtraction.new(table[:total_space], table[:used_space])

      @actual_tokens = Token.active.where(free_space.gt(resource_size)).pluck(:id, free_space).to_h
    end
  end
end
