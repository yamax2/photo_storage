# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
# require "active_job/railtie"
require 'active_record/railtie'
# require "active_storage/engine"
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
# require "action_cable/engine"
require 'sprockets/railtie'
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module PhotoStorage
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.time_zone = ENV.fetch('TZ', 'Asia/Yekaterinburg')

    config.i18n.default_locale = :ru
    config.i18n.fallbacks = %i[en]
    config.i18n.enforce_available_locales = true

    config.eager_load_paths += %W[
      #{config.root}/lib
    ]

    config.action_dispatch.rescue_responses['Yandex::BackupInfoService::WrongResourceError'] = :bad_request
    config.action_dispatch.rescue_responses['ReportQuery::Error'] = :not_found

    config.redis = config_for(:redis)

    require 'logging/subscriber'
    require 'logging/formatter'
    require 'redis_helper'

    config.after_initialize do
      RailsSemanticLogger.swap_subscriber(
        RailsSemanticLogger::ActionController::LogSubscriber,
        Logging::Subscriber,
        :action_controller
      )
    end

    include RedisHelper
  end
end
