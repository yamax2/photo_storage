# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  def proxy_url
    "#{Rails.application.routes.default_url_options[:protocol]}://#{Rails.application.config.proxy_domain}." \
      "#{Rails.application.routes.default_url_options[:host]}"
  end
end
