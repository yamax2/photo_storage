Date::DATE_FORMATS[:default] = '%d.%m.%Y'
Time::DATE_FORMATS[:default] = '%d.%m.%Y %H:%M'

Rails.application.routes.default_url_options[:host] = ENV.fetch('HOST', 'photostorage.localhost')
Rails.application.routes.default_url_options[:protocol] = ENV.fetch('PROTOCOL', 'http')

Rails.application.configure do
  config.proxy_domain = ENV.fetch('PROXY_SUBDOMAIN', 'proxy').freeze

  # widths
  config.photo_sizes = {
    thumb: ->(photo) { photo.width * 360 / photo.height },
    preview: ->(photo) { photo.width * 800 / photo.height }
  }

  # allowed timezones
  config.photo_timezones = [
    Rails.application.config.time_zone,
    'Europe/Moscow'
  ]

  config.admin_emails = ENV.fetch('ADMIN_EMAILS', 'admin@photostorage.localhost').split(',').map(&:strip)
end
