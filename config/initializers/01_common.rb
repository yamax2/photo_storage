# frozen_string_literal: true

Date::DATE_FORMATS[:default] = '%d.%m.%Y'
Time::DATE_FORMATS[:default] = '%d.%m.%Y %H:%M:%S'

Rails.application.routes.default_url_options[:host] = ENV.fetch('HOST', 'photostorage.localhost')
Rails.application.routes.default_url_options[:protocol] = ENV.fetch('PROTOCOL', 'http')

Rails.application.configure do
  config.custom_text_matchers = [
    /^IMG(_|\s)\d+/,
    /^VID(_|\s)\d+/,
    /^DSCN\d+/,
    /^P(_|\s)\d{8}(_|\s)\d{6}/,
    /^\d{8}(_|\s)\d{6}/,
    /^f\d{9}/,
    /^IMAG\d+/,
    /^SDC\d+/
  ].freeze

  # widths
  config.photo_sizes = {
    thumb: ->(photo) { photo.width * 360 / photo.height },

    preview: lambda do |photo|
      size = photo.width * 800 / photo.height
      size = 1_280 if size > 1_280

      size
    end,

    max: lambda do |photo|
      size = photo.width * 960 / photo.height
      size = 1280 if size > 1_280

      size
    end,

    p2k: lambda do |photo|
      size =
        if photo.height > 1_140
          photo.width * 1_140 / photo.height
        else
          photo.width
        end

      size = 2_000 if size > 2_000
      size
    end
  }

  # allowed timezones
  config.photo_timezones =
    if (timezones = ENV.fetch('PHOTOSTORAGE_ADDITIONAL_TIMEZONES', nil)).present?
      [
        Rails.application.config.time_zone,
        *timezones.split(',').map(&:strip)
      ].uniq
    else
      YAML.load_file(
        Rails.application.config.root.join('config', 'time_zones.yml')
      )
    end

  config.admin_emails = ENV.fetch('PHOTOSTORAGE_ADMIN_EMAILS', 'admin@photostorage.localhost').split(',').map(&:strip)
  config.default_map_center = [56.799631, 60.596571]

  # delay for slideshow, seconds
  config.slideshow_delay = ENV.fetch('PHOTOSTORAGE_SLIDESHOW_DELAY', 2).to_i
end
