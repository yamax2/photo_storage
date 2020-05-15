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

  # FIXME: url??
  def url(size = :original)
    return if storage_filename.blank?

    path = "#{yandex_token.dir.sub(%r{^/}, '')}/#{storage_filename}"
    method = size == :original ? :proxy_object_path : :proxy_object_preview_path

    Rails.application.routes.url_helpers.public_send(method, path, params_for_size(size))
  end

  private

  delegate :max_thumb_width, :photo_sizes, to: 'Rails.application.config'

  def actual_width_for(width)
    width > max_thumb_width ? max_thumb_width : width
  end

  def params_for_size(size)
    {id: yandex_token_id}.tap do |params|
      if size == :original
        params[:fn] = original_filename
      else
        params[:size] = actual_width_for(thumb_width(size))
      end
    end
  end

  def thumb_width(size)
    width = photo_sizes.fetch(size)

    if width.respond_to?(:call)
      width.call(self)
    else
      width
    end
  end
end
