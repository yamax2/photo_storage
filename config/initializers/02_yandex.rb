YandexPhotoStorage.configure do |config|
  # config.api_key = ''
  # config.api_secret = ''
  config.logger = Logger.new(Rails.root.join('log', "yandex_#{Rails.env}.log"))
end
