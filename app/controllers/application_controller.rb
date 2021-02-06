# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :current_user

  def current_user
    @current_user ||= User.new(
      request.headers['HTTP_AUTHORIZATION']
    )
  end
end
