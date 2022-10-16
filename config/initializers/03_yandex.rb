# frozen_string_literal: true

YandexClient.configure do |config|
  unless Rails.env.test?
    config.api_key = Rails.application.credentials.yandex&.[](:api_key)
    config.api_secret = Rails.application.credentials.yandex&.[](:api_secret)
  end

  config.logger = Logger.new(Rails.root.join('log', "yandex_#{Rails.env}.log")) unless Rails.env.test?
  config.read_timeout = 5.minutes
end
