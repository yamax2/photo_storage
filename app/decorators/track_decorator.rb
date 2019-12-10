# frozen_string_literal: true

class TrackDecorator < Draper::Decorator
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
end
