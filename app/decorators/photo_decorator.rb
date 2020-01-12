# frozen_string_literal: true

class PhotoDecorator < ApplicationDecorator
  delegate_all

  def current_views
    views + inc_counter
  end

  def image_size(size = :thumb)
    thumb_width = thumb_width(size)

    [thumb_width, height * thumb_width / width]
  end

  def url(size = :original)
    return if storage_filename.blank?

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

  delegate :max_photo_width, :photo_sizes, to: 'Rails.application.config'

  def thumb_width(size)
    width = photo_sizes.fetch(size)

    width = width.call(self) if width.respond_to?(:call)
    width = max_photo_width if width > max_photo_width

    width
  end

  def url_components(original)
    [proxy_url].tap do |components|
      components << 'originals' if original

      components << yandex_token.dir.sub(%r{^/}, '')
      components << storage_filename
    end
  end
end
