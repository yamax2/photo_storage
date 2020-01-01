# frozen_string_literal: true

class TrackDecorator < ApplicationDecorator
  delegate_all

  def avg_speed
    super.round(2)
  end

  def distance
    super.round(2)
  end

  def duration
    (super / 3600.0).round(2)
  end

  def url
    return if storage_filename.blank?

    [
      proxy_url,
      'originals',
      yandex_token.other_dir.sub(%r{^/}, ''),
      storage_filename
    ].join('/').tap do |url|
      url << "?fn=#{original_filename}"
      url << "&id=#{yandex_token_id}"
    end
  end
end
