# frozen_string_literal: true

class RedisScriptService
  def initialize(script)
    @script = script
  end

  def call(keys: [], argv: [])
    redis.evalsha(script_sha1, keys: Array.wrap(keys), argv: Array.wrap(argv))
  rescue Redis::CommandError => e
    raise unless e.message.start_with?('NOSCRIPT')

    redis.eval(@script, keys: Array.wrap(keys), argv: Array.wrap(argv))
  end

  private

  delegate :redis, to: RedisClassy

  def script_sha1
    Digest::SHA1.hexdigest(@script)
  end
end
