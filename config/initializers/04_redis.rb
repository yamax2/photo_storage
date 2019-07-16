unless Rails.env.test?
  config = Rails.root.join('config', 'redis.yml')

  if File.exist?(config)
    opts = YAML.load_file(config).fetch(Rails.env)
    Rails.application.config.redis_options = opts

    Redis.current = Redis.new(opts)
  end

  RedisClassy.redis = Redis.current
end
