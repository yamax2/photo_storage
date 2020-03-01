# frozen_string_literal: true

YandexClient.configure do |config|
  unless Rails.env.test?
    config.api_key = ENV['PHOTOSTORAGE_YANDEX_API_KEY'] || Rails.application.credentials.yandex.try(:[], :api_key)
    config.api_secret =
      ENV['PHOTOSTORAGE_YANDEX_API_SECRET'] || Rails.application.credentials.yandex.try(:[], :api_secret)
  end

  config.logger = Logger.new(Rails.root.join('log', "yandex_#{Rails.env}.log"))
  config.read_timeout = 2.minutes
end
