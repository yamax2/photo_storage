# frozen_string_literal: true

Date::DATE_FORMATS[:default] = '%d.%m.%Y'
Time::DATE_FORMATS[:default] = '%d.%m.%Y %H:%M:%S'

Rails.application.routes.default_url_options[:host] = ENV.fetch('HOST', 'photostorage.localhost')
Rails.application.routes.default_url_options[:protocol] = ENV.fetch('PROTOCOL', 'http')

Rails.application.configure do
  # widths
  config.photo_sizes = {
    thumb: ->(photo) { photo.width * 360 / photo.height },
    preview: ->(photo) { photo.width * 800 / photo.height },
    max: ->(photo) { photo.width * 960 / photo.height }
  }

  # yandex max width
  config.max_thumb_width = 1280

  # allowed timezones
  config.photo_timezones = [
    Rails.application.config.time_zone,
    *ENV.fetch('PHOTOSTORAGE_ADDITIONAL_TIMEZONES', 'Europe/Moscow,Europe/Samara').split(',').map(&:strip)
  ].uniq

  config.admin_emails = ENV.fetch('PHOTOSTORAGE_ADMIN_EMAILS', 'admin@photostorage.localhost').split(',').map(&:strip)
  config.default_map_center = [56.799631, 60.596571]
end
