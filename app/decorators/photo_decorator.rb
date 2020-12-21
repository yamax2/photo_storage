# frozen_string_literal: true

class PhotoDecorator < ApplicationDecorator
  delegate_all

  ROTATED_DEG = {
    1 => 90,
    2 => 180,
    3 => 270
  }.freeze
  private_constant :ROTATED_DEG

  def current_views
    views + inc_counter
  end

  def image_size(size = :thumb, apply_rotation: false)
    reversed = turned?
    actual_size = (@image_size ||= {})[size] ||= calc_image_size(size, reversed)

    if reversed && apply_rotation
      actual_size.reverse
    else
      actual_size
    end
  end

  def css_transform
    transforms = []

    transforms += Array.wrap(effects)
    transforms << "rotate(#{ROTATED_DEG.fetch(rotated)}deg)" if rotated

    transforms.join(' ').presence
  end

  def turned?
    rotated.to_i.odd?
  end

  # FIXME: url??
  def url(size = :original)
    return if storage_filename.blank?

    path = "#{yandex_token.dir.sub(%r{^/}, '')}/#{storage_filename}"
    method = size == :original ? :proxy_object_path : :proxy_object_preview_path

    Rails.application.routes.url_helpers.public_send(method, path, params_for_size(size))
  end

  private

  delegate :max_thumb_width, :photo_sizes, to: 'Rails.application.config'

  def calc_image_size(size, reversed)
    thumb_width = thumb_width(size)

    [
      thumb_width,
      height * thumb_width / width
    ].tap do |result|
      if reversed
        result.reverse!

        result[1] = result.first**2 / result.last
      end
    end
  end

  def params_for_size(size)
    {id: yandex_token_id}.tap do |params|
      if size == :original
        params[:fn] = original_filename
      else
        params[:size] = image_size(size).first
      end
    end
  end

  def thumb_width(size)
    result = photo_sizes.fetch(size)

    result = result.call(self) if result.respond_to?(:call)
    result = width if size != :thumb && result > width
    result = max_thumb_width if result > max_thumb_width

    result
  end
end
