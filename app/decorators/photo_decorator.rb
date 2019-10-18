# frozen_string_literal: true

class PhotoDecorator < Draper::Decorator
  delegate_all

  def current_views
    views + inc_counter
  end

  def image_size(size = :thumb)
    thumb_width = thumb_width(size)

    [thumb_width, height * thumb_width / width]
  end

  def url(size = :original)
    return unless storage_filename.present?

    original = size == :original
    url = url_components(original).join('/')

    url << if original
             "?fn=#{original_filename}"
           else
             "?preview&size=#{thumb_width(size)}"
           end

    url << "&id=#{yandex_token_id}"
    url
  end

  private

  def proxy_url
    "#{Rails.application.routes.default_url_options[:protocol]}://#{Rails.application.config.proxy_domain}." \
      "#{Rails.application.routes.default_url_options[:host]}"
  end

  def thumb_width(size)
    width = Rails.application.config.photo_sizes.fetch(size)

    if width.respond_to?(:call)
      width.call(self)
    else
      width
    end
  end

  def url_components(original)
    [proxy_url].tap do |components|
      components << 'originals' if original

      components << yandex_token.dir.sub(%r{^/}, '')
      components << storage_filename
    end
  end
end
