# frozen_string_literal: true

class PhotoDecorator < ApplicationDecorator
  delegate_all

  def proxy_url(size = :original)
    url_generator.generate(
      size,
      size == :original ? nil : image_size(size)
    )
  end

  delegate :image_size, :css_transform, :turned?, to: :image_props

  private

  def image_props
    @image_props ||= ::Listing::ImageProps.new(object)
  end

  def url_generator
    @url_generator ||= ::ProxyUrls::Photo.new(object)
  end
end
