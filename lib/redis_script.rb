# frozen_string_literal: true

class RedisScript
  def initialize(script)
    @script = script
  end

  def exec(keys: [], argv: [])
    wrapped_keys = Array.wrap(keys)
    begin
      redis.call('EVALSHA', script_sha1, wrapped_keys.size, *wrapped_keys, *Array.wrap(argv))
    rescue RedisClient::CommandError => e
      raise unless e.message.start_with?('NOSCRIPT')

      redis.call('EVAL', @script, wrapped_keys.size, *wrapped_keys, *Array.wrap(argv))
    end
  end

  private

  delegate :redis, to: 'Rails.application', private: true

  def script_sha1
    Digest::SHA1.hexdigest(@script)
  end
end
