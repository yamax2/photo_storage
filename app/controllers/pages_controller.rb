class PagesController < ApplicationController
  def index
    @page = Page.new(params[:id])
  end
end
