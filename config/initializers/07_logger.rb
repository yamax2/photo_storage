# frozen_string_literal: true

Rails.application.configure do
  config.log_level = ENV.fetch('LOG_LEVEL', 'debug').to_sym
end
