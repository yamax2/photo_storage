# frozen_string_literal: true

module Yandex
  class TokenForUploadService
    include ::Interactor

    CACHE_REDIS_KEY = 'yandex_tokens_usage'
    FIND_SCRIPT = <<~LUA
      local cache_values = redis.call("HGETALL", KEYS[1])
      local cache = {}
      for idx = 1, #cache_values, 2 do
        cache[cache_values[idx]] = cache_values[idx + 1]
      end
      local info = cjson.decode(ARGV[1])
      local result = {}
      for id, space in pairs(info) do
        local current_space = cache[id] or 0
        current_space = current_space + ARGV[2]
        if current_space < space then
          table.insert(result, id)
        end
      end
      if table.getn(result) > 0 then
        local id = math.min(unpack(result))
        redis.call("HINCRBY", KEYS[1], id, ARGV[2])
        return id
      end
    LUA

    private_constant :FIND_SCRIPT
    delegate :resource_size, :token_id, to: :context

    def call
      return if actual_tokens.empty?

      token_id = RedisScriptService.
        new(FIND_SCRIPT).
        call(
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
