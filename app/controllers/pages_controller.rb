class PagesController < ApplicationController
  def show
    @page = Page.new(params[:id])
  end
end
