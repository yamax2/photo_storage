YandexPhotoStorage.configure do |config|
  unless Rails.env.test?
    config.api_key = Rails.application.credentials.yandex.fetch(:api_key)
    config.api_secret = Rails.application.credentials.yandex.fetch(:api_secret)
  end

  config.logger = Logger.new(Rails.root.join('log', "yandex_#{Rails.env}.log"))
end
