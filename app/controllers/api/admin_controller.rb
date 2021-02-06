# frozen_string_literal: true

module Api
  class AdminController < BaseController
    before_action do
      render json: {status: :forbidden}, status: :forbidden unless current_user.admin?
    end
  end
end
