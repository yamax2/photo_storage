# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  delegate :proxy_url, to: 'Rails.application'
end
