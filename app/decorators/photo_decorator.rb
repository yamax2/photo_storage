# frozen_string_literal: true

class PhotoDecorator < ApplicationDecorator
  delegate_all

  def current_views
    views + inc_counter
  end

  def image_size(size = :thumb)
    thumb_width = thumb_width(size)

    [
      actual_width_for(thumb_width),
      height * thumb_width / width
    ]
  end

  def url(size = :original)
    return if storage_filename.blank?

    original = size == :original
    url = url_components(original).join('/')

    url << if original
             "?fn=#{original_filename}"
           else
             "?preview&size=#{actual_width_for(thumb_width(size))}"
           end

    url << "&id=#{yandex_token_id}"
    url
  end

  private

  delegate :max_thumb_width, :photo_sizes, to: 'Rails.application.config'

  def actual_width_for(width)
    width > max_thumb_width ? max_thumb_width : width
  end

  def thumb_width(size)
    width = photo_sizes.fetch(size)

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
