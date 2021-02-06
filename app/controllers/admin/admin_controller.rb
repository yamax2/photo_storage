# frozen_string_literal: true

module Admin
  # Base admin controller
  class AdminController < ApplicationController
    layout 'admin'

    before_action { head :forbidden unless current_user.admin? }
  end
end
