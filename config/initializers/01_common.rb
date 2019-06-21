Date::DATE_FORMATS[:default] = '%d.%m.%Y'
Time::DATE_FORMATS[:default] = '%d.%m.%Y %H:%M'

Rails.application.routes.default_url_options[:host] = ENV.fetch('HOST', 'photostorage.localhost')
Rails.application.routes.default_url_options[:protocol] = ENV.fetch('PROTOCOL', 'http')

Rails.application.configure do
  config.proxy_domain = 'proxy'.freeze
  config.photo_sizes = {
    thumb: 400,
    preview: 1200
  }
end
