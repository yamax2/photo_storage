module Admin
  # Base admin controller
  class AdminController < ApplicationController
    layout 'admin'

    # before_action :authenticate_user!
    # before_action :admin_restriction

    # private

    # def admin_restriction
    #  return if current_user&.admin?

    #  respond_to do |format|
    #    format.html { redirect_to admin_root_path }
    #    format.js { render body: nil, status: :not_found }
    #  end
    # end
  end
end
