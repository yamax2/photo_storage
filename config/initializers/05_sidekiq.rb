# frozen_string_literal: true

require 'sidekiq/throttled'

Sidekiq::Throttled.setup!
Sidekiq::Extensions.enable_delay!

if (opts = Rails.application.config.try(:redis))
  Sidekiq.configure_server do |config|
    config.redis = opts
    # config.error_handlers << proc { |ex, ctx_hash| ErrorMailer.delay.error_msg(ex, ctx_hash) }

    schedule_file = Rails.application.config.root.join('config', 'schedule.yml')
    if File.exist?(schedule_file) && Sidekiq.server?
      Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file))
    end
  end

  Sidekiq.configure_client { |config| config.redis = opts }
end
