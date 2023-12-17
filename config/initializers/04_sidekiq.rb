# frozen_string_literal: true

require 'sidekiq/throttled'

# rubocop:disable Lint/ConstantDefinitionInBlock
if (opts = Rails.application.config.try(:redis))
  # https://github.com/reidmorrison/semantic_logger/discussions/221
  Sidekiq.configure_server do |config|
    TaggedJobLogger = Class.new(Sidekiq::JobLogger) do
      def call(item, queue)
        @logger.tagged(Sidekiq::Context.current) do
          super(item, queue)
        end
      end
    end

    config.redis = opts
    # config.error_handlers << proc { |ex, ctx_hash| ErrorMailer.delay.error_msg(ex, ctx_hash) }

    schedule_file = Rails.application.config.root.join('config', 'schedule.yml')
    Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file)) if File.exist?(schedule_file) && Sidekiq.server?

    config[:job_logger] = TaggedJobLogger
  end

  Sidekiq.configure_client { |config| config.redis = opts }
end
# rubocop:enable Lint/ConstantDefinitionInBlock
