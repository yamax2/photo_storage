# frozen_string_literal: true

module Api
  class BaseController < ::ActionController::API
    helper_method :current_user

    def current_user
      @current_user ||= User.new(
        request.headers['HTTP_AUTHORIZATION']
      )
    end
  end
end
