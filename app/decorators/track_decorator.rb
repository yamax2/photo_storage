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
    Formatters::Duration.new(super).call
  end

  def proxy_url
    url_generator.generate
  end

  private

  def url_generator
    @url_generator ||= ::ProxyUrls::Track.new(object)
  end
end
