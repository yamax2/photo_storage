# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :start_proxy_session

  def start_proxy_session
    new_session = ProxySessionService.new(cookies[:proxy_session]).call

    return if new_session.nil?

    cookies[:proxy_session] = {
      value: new_session,
      domain: ".#{Rails.application.routes.default_url_options[:host]}"
    }
  end
end
